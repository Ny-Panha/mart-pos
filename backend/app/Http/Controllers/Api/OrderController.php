<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with(['cashier:id,name', 'items'])
            ->orderBy('created_at', 'desc')
            ->take(50)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    public function show($id)
    {
        $order = Order::with(['cashier:id,name', 'customer', 'items.product'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $order,
        ]);
    }

    private function isEquivalentPayload(Order $existing, array $validated): bool
    {
        if ((int) $existing->total_riel !== (int) $validated['total_riel']) {
            return false;
        }
        if ($existing->payment_method !== $validated['payment_method']) {
            return false;
        }

        $existingItems = [];
        foreach ($existing->items as $item) {
            $pid = (int) $item->product_id;
            $existingItems[$pid] = ($existingItems[$pid] ?? 0) + (int) $item->qty;
        }

        $incomingItems = [];
        foreach ($validated['items'] as $item) {
            $pid = (int) $item['product_id'];
            $incomingItems[$pid] = ($incomingItems[$pid] ?? 0) + (int) $item['qty'];
        }

        ksort($existingItems);
        ksort($incomingItems);

        return $existingItems === $incomingItems;
    }

    public function store(Request $request)
    {
        // Must be authenticated user
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated cashier. Please log in.',
            ], 401);
        }

        $validated = $request->validate([
            'client_operation_id' => 'required|string|min:8|max:64',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.custom_price' => 'nullable|integer|min:0',
            'discount_riel' => 'nullable|integer|min:0',
            'tax_riel' => 'nullable|integer|min:0',
            'total_riel' => 'required|integer|min:0',
            'total_usd' => 'nullable|numeric|min:0',
            'received_riel' => 'nullable|integer|min:0',
            'received_usd' => 'nullable|numeric|min:0',
            'change_riel' => 'nullable|integer|min:0',
            'change_usd' => 'nullable|numeric|min:0',
            'payment_method' => 'required|string|in:cash_riel,cash_usd,khqr,cash',
            'invoice_number' => 'nullable|string|max:100',
            'notes' => 'nullable|string',
        ]);

        $opId = $validated['client_operation_id'];

        // 1. Idempotency Check & User Binding & Equivalent Payload
        $existing = Order::with(['cashier:id,name', 'items'])
            ->where('client_operation_id', $opId)
            ->first();

        if ($existing) {
            if ($existing->cashier_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cross-user idempotency violation: Operation ID is already registered to another user.',
                ], 403);
            }

            if (!$this->isEquivalentPayload($existing, $validated)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conflict: client_operation_id already used with a different payload.',
                ], 409);
            }

            return response()->json([
                'success' => true,
                'message' => 'Order already processed (idempotent recovery)',
                'data' => $existing,
            ], 200);
        }

        try {
            return DB::transaction(function () use ($validated, $request, $user, $opId) {
                // Check double-request race condition
                $dup = Order::where('client_operation_id', $opId)
                    ->lockForUpdate()
                    ->first();
                if ($dup) {
                    if ($dup->cashier_id !== $user->id) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Cross-user idempotency violation: Operation ID is already registered to another user.',
                        ], 403);
                    }
                    if (!$this->isEquivalentPayload($dup, $validated)) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Conflict: client_operation_id already used with a different payload.',
                        ], 409);
                    }
                    return response()->json([
                        'success' => true,
                        'message' => 'Order already processed (idempotent recovery)',
                        'data' => $dup->load(['cashier:id,name', 'items']),
                    ], 200);
                }

                // 2. Aggregate quantities by product ID
                $aggregatedQty = [];
                foreach ($validated['items'] as $item) {
                    $pid = (int) $item['product_id'];
                    $aggregatedQty[$pid] = ($aggregatedQty[$pid] ?? 0) + (int) $item['qty'];
                }

                // 3. Deterministic locking: sort by product ID ascending to prevent deadlocks
                ksort($aggregatedQty);
                $lockedProducts = [];
                foreach (array_keys($aggregatedQty) as $pid) {
                    $lockedProducts[$pid] = Product::lockForUpdate()->findOrFail($pid);
                }

                // 4. Validate aggregate stock and active status
                foreach ($aggregatedQty as $pid => $totalQty) {
                    $prod = $lockedProducts[$pid];
                    if ($prod->status !== 'active') {
                        return response()->json([
                            'success' => false,
                            'message' => "Product \"{$prod->name}\" is inactive and cannot be sold.",
                        ], 422);
                    }
                    if ($prod->stock_qty < $totalQty) {
                        return response()->json([
                            'success' => false,
                            'message' => "Insufficient aggregate stock for \"{$prod->name}\". Available: {$prod->stock_qty}, requested: {$totalQty}.",
                        ], 422);
                    }
                }

                // 5. Server-side Recalculation & Authorization
                $userRole = strtoupper(trim((string) $user->role));
                $isAdminOrManager = in_array($userRole, ['ADMIN_MANAGER', 'ADMIN'], true);

                $calculatedSubtotal = 0;
                $processedItems = [];

                foreach ($validated['items'] as $item) {
                    $prod = $lockedProducts[$item['product_id']];
                    $unitPrice = $prod->sale_price;

                    if (isset($item['custom_price']) && $item['custom_price'] !== null) {
                        $customPrice = (int) $item['custom_price'];
                        if ($customPrice !== $prod->sale_price && !$isAdminOrManager) {
                            return response()->json([
                                'success' => false,
                                'message' => 'Cashiers are not authorized to override item prices.',
                            ], 403);
                        }
                        $unitPrice = $customPrice;
                    }

                    $qty = (int) $item['qty'];
                    $subtotal = $unitPrice * $qty;
                    $calculatedSubtotal += $subtotal;

                    $processedItems[] = [
                        'product' => $prod,
                        'qty' => $qty,
                        'unit_price' => $unitPrice,
                        'subtotal' => $subtotal,
                    ];
                }

                $discountRiel = (int) ($validated['discount_riel'] ?? 0);
                if ($discountRiel > 0 && !$isAdminOrManager) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Cashiers are not authorized to apply discounts without manager approval.',
                    ], 403);
                }
                if ($discountRiel > $calculatedSubtotal) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Discount cannot exceed order subtotal.',
                    ], 422);
                }

                $taxRiel = (int) ($validated['tax_riel'] ?? 0);
                $expectedTotalRiel = max(0, $calculatedSubtotal - $discountRiel + $taxRiel);

                if ((int) $validated['total_riel'] !== $expectedTotalRiel) {
                    return response()->json([
                        'success' => false,
                        'message' => "Total amount mismatch. Expected: {$expectedTotalRiel} Riel, received: {$validated['total_riel']} Riel.",
                    ], 422);
                }

                // 6. Validate payment totals and change amounts
                $paymentMethod = $validated['payment_method'];
                $receivedRiel = (int) ($validated['received_riel'] ?? 0);
                $changeRiel = (int) ($validated['change_riel'] ?? 0);

                if ($paymentMethod === 'khqr') {
                    if ($receivedRiel !== $expectedTotalRiel) {
                        return response()->json([
                            'success' => false,
                            'message' => 'KHQR payment received amount must exactly equal total amount.',
                        ], 422);
                    }
                    if ($changeRiel !== 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'KHQR payment cannot have change amount.',
                        ], 422);
                    }
                } else {
                    if ($receivedRiel < $expectedTotalRiel) {
                        return response()->json([
                            'success' => false,
                            'message' => "Insufficient payment received. Total: {$expectedTotalRiel}, received: {$receivedRiel}.",
                        ], 422);
                    }
                    $expectedChange = $receivedRiel - $expectedTotalRiel;
                    if ($changeRiel !== $expectedChange) {
                        return response()->json([
                            'success' => false,
                            'message' => "Change amount mismatch. Expected: {$expectedChange}, received: {$changeRiel}.",
                        ], 422);
                    }
                }

                // 7. Establish Invoice Number
                $invoiceNumber = $validated['invoice_number'] ?? null;
                if (empty($invoiceNumber) || Order::where('invoice_number', $invoiceNumber)->exists()) {
                    $invoiceNumber = 'INV-' . date('Ymd') . '-' . strtoupper(Str::random(5));
                }

                // 8. Create Order
                $order = Order::create([
                    'invoice_number' => $invoiceNumber,
                    'client_operation_id' => $opId,
                    'cashier_id' => $user->id,
                    'customer_id' => $request->customer_id ?? null,
                    'discount_riel' => $discountRiel,
                    'tax_riel' => $taxRiel,
                    'total_riel' => $expectedTotalRiel,
                    'total_usd' => $validated['total_usd'] ?? round($expectedTotalRiel / 4100, 2),
                    'received_riel' => $receivedRiel,
                    'received_usd' => $validated['received_usd'] ?? 0,
                    'change_riel' => $changeRiel,
                    'change_usd' => $validated['change_usd'] ?? 0,
                    'payment_method' => $paymentMethod,
                    'status' => 'completed',
                    'notes' => $validated['notes'] ?? null,
                ]);

                // 9. Create Order Items
                foreach ($processedItems as $entry) {
                    $prod = $entry['product'];
                    $qty = $entry['qty'];

                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $prod->id,
                        'product_name' => $prod->name,
                        'qty' => $qty,
                        'cost_price' => $prod->cost_price,
                        'sale_price' => $entry['unit_price'],
                        'subtotal' => $entry['subtotal'],
                    ]);
                }

                // 10. Deduct aggregate stock once per product and record stock movement
                foreach ($aggregatedQty as $pid => $totalQty) {
                    $prod = $lockedProducts[$pid];
                    $stockBefore = $prod->stock_qty;
                    $prod->decrement('stock_qty', $totalQty);
                    $stockAfter = $stockBefore - $totalQty;

                    StockMovement::create([
                        'product_id' => $prod->id,
                        'type' => 'sale',
                        'qty' => -$totalQty,
                        'stock_before' => $stockBefore,
                        'stock_after' => $stockAfter,
                        'note' => 'POS Sale: ' . $order->invoice_number,
                        'ref_id' => $order->invoice_number,
                        'created_by' => $user->id,
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Order created and stock updated successfully',
                    'data' => $order->load(['cashier:id,name', 'items']),
                ], 201);
            });
        } catch (\Illuminate\Database\QueryException $e) {
            // Handle race-condition unique constraint duplicate entry
            if ($e->getCode() === '23000') {
                $committed = Order::with(['cashier:id,name', 'items'])
                    ->where('client_operation_id', $opId)
                    ->first();
                if ($committed) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Order already processed (idempotent recovery)',
                        'data' => $committed,
                    ], 200);
                }
            }
            throw $e;
        }
    }
}
