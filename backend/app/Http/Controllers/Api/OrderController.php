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

    public function findByOperationId(Request $request, $opId)
    {
        $user = $request->user();
        $order = Order::with(['cashier:id,name', 'items.product'])
            ->where('client_operation_id', $opId)
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Operation not found',
            ], 404);
        }

        if ($order->cashier_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Cross-user idempotency violation: Operation ID is already registered to another user.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $order,
        ]);
    }

    public function abortOperation(Request $request, $opId)
    {
        $user = $request->user();

        return DB::transaction(function () use ($opId, $user) {
            $existing = Order::with(['cashier:id,name', 'items'])
                ->where('client_operation_id', $opId)
                ->lockForUpdate()
                ->first();

            if ($existing) {
                if ($existing->cashier_id !== $user->id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Cross-user violation: Operation ID belongs to another user.',
                    ], 403);
                }

                if ($existing->status === 'cancelled') {
                    return response()->json([
                        'success' => true,
                        'aborted' => true,
                        'message' => 'Operation was already cancelled.',
                    ]);
                }

                // Order has already committed as completed!
                return response()->json([
                    'success' => false,
                    'committed' => true,
                    'message' => 'Cannot abort: Order has already committed.',
                    'data' => $existing,
                ], 409);
            }

            // Order does not exist yet. Atomically claim client_operation_id with a cancelled tombstone record!
            // Any in-flight POST /orders that attempts to commit will collide on the unique index.
            $invoiceNumber = 'ABORT-' . strtoupper(Str::random(12));
            $cancelledOrder = Order::create([
                'invoice_number' => $invoiceNumber,
                'client_operation_id' => $opId,
                'cashier_id' => $user->id,
                'total_riel' => 0,
                'total_usd' => 0.00,
                'received_riel' => 0,
                'received_usd' => 0.00,
                'change_riel' => 0,
                'change_usd' => 0.00,
                'payment_method' => 'cash_riel',
                'status' => 'cancelled',
                'notes' => 'Authoritatively aborted by cashier prior to completion.',
            ]);

            return response()->json([
                'success' => true,
                'aborted' => true,
                'message' => 'Operation authoritatively aborted.',
                'data' => $cancelledOrder,
            ]);
        });
    }

    private function isEquivalentPayload(Order $existing, array $validated): bool
    {
        // 1. Validate complete financial totals
        if ((int) $existing->total_riel !== (int) $validated['total_riel']) {
            return false;
        }
        if ((int) $existing->discount_riel !== (int) ($validated['discount_riel'] ?? 0)) {
            return false;
        }
        if ((int) $existing->tax_riel !== (int) ($validated['tax_riel'] ?? 0)) {
            return false;
        }

        // 2. Validate payment method and tendered amounts
        if ($existing->payment_method !== $validated['payment_method']) {
            return false;
        }
        if (isset($validated['received_riel']) && (int) $existing->received_riel !== (int) $validated['received_riel']) {
            return false;
        }
        if (isset($validated['change_riel']) && (int) $existing->change_riel !== (int) $validated['change_riel']) {
            return false;
        }
        if ($existing->payment_method === 'cash_usd') {
            if (isset($validated['received_usd']) && abs((float) $existing->received_usd - (float) $validated['received_usd']) > 0.01) {
                return false;
            }
            if (isset($validated['change_usd']) && abs((float) $existing->change_usd - (float) $validated['change_usd']) > 0.01) {
                return false;
            }
        }

        // 3. Validate line items: product_id, aggregate qty, and unit price
        $existingItems = [];
        foreach ($existing->items as $item) {
            $pid = (int) $item->product_id;
            if (!isset($existingItems[$pid])) {
                $existingItems[$pid] = ['qty' => 0, 'sale_price' => (int) $item->sale_price];
            }
            $existingItems[$pid]['qty'] += (int) $item->qty;
        }

        $incomingItems = [];
        foreach ($validated['items'] as $item) {
            $pid = (int) $item['product_id'];
            if (!isset($incomingItems[$pid])) {
                $customPrice = isset($item['custom_price']) && $item['custom_price'] !== null ? (int) $item['custom_price'] : null;
                $incomingItems[$pid] = ['qty' => 0, 'custom_price' => $customPrice];
            }
            $incomingItems[$pid]['qty'] += (int) $item['qty'];
        }

        if (count($existingItems) !== count($incomingItems)) {
            return false;
        }

        ksort($existingItems);
        ksort($incomingItems);

        foreach ($incomingItems as $pid => $data) {
            if (!isset($existingItems[$pid])) {
                return false;
            }
            if ($existingItems[$pid]['qty'] !== $data['qty']) {
                return false;
            }
            if ($data['custom_price'] !== null && $existingItems[$pid]['sale_price'] !== $data['custom_price']) {
                return false;
            }
        }

        return true;
    }

    private function resolveIdempotentOrder(Order $order, array $validated, $user): \Illuminate\Http\JsonResponse
    {
        if ($order->status === 'cancelled') {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: Operation ID was aborted/cancelled and cannot be committed.',
            ], 409);
        }

        if ($order->cashier_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Cross-user idempotency violation: Operation ID is already registered to another user.',
            ], 403);
        }

        if (!$this->isEquivalentPayload($order, $validated)) {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: client_operation_id already used with a different payload.',
            ], 409);
        }

        return response()->json([
            'success' => true,
            'message' => 'Order already processed (idempotent recovery)',
            'data' => $order->loadMissing(['cashier:id,name', 'items.product']),
        ], 200);
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
            'tax_rate' => 'nullable|numeric|min:0|max:0.30',
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
            return $this->resolveIdempotentOrder($existing, $validated, $user);
        }

        try {
            return DB::transaction(function () use ($validated, $request, $user, $opId) {
                // Check double-request race condition
                $dup = Order::where('client_operation_id', $opId)
                    ->lockForUpdate()
                    ->first();
                if ($dup) {
                    return $this->resolveIdempotentOrder($dup, $validated, $user);
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

                // Server-side Tax Policy: explicit calculation policy
                $taxableBase = max(0, $calculatedSubtotal - $discountRiel);
                if (isset($validated['tax_rate']) && $validated['tax_rate'] !== null) {
                    $taxRate = (float) $validated['tax_rate'];
                    if ($taxRate < 0.0 || $taxRate > 0.30) {
                        return response()->json([
                            'success' => false,
                            'message' => "Invalid tax rate: {$taxRate}. Must be between 0.0 and 0.30.",
                        ], 422);
                    }
                    $expectedTaxRiel = (int) round($taxableBase * $taxRate);
                    if (isset($validated['tax_riel']) && abs((int) $validated['tax_riel'] - $expectedTaxRiel) > 2) {
                        return response()->json([
                            'success' => false,
                            'message' => "Inconsistent tax amount. Server calculated {$expectedTaxRiel} Riel for rate {$taxRate}, client sent {$validated['tax_riel']} Riel.",
                        ], 422);
                    }
                    $taxRiel = $expectedTaxRiel;
                } else {
                    $taxRiel = (int) ($validated['tax_riel'] ?? 0);
                    if ($taxRiel > 0 && $taxableBase > 0) {
                        $impliedRate = $taxRiel / $taxableBase;
                        if ($impliedRate > 0.30) {
                            return response()->json([
                                'success' => false,
                                'message' => "Invalid or manipulated tax amount: {$taxRiel} Riel exceeds allowable policy limit (30%).",
                            ], 422);
                        }
                    } elseif ($taxRiel > 0 && $taxableBase === 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Cannot apply tax to a zero taxable base.',
                        ], 422);
                    }
                }

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
                } elseif ($paymentMethod === 'cash_usd') {
                    $expectedTotalUsd = round($expectedTotalRiel / 4100, 2);
                    $receivedUsd = round((float) ($validated['received_usd'] ?? 0.0), 2);
                    $changeUsd = round((float) ($validated['change_usd'] ?? 0.0), 2);

                    if ($receivedUsd <= 0.0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Cash USD payment requires a positive received_usd amount.',
                        ], 422);
                    }

                    if ($receivedUsd < $expectedTotalUsd) {
                        return response()->json([
                            'success' => false,
                            'message' => "Insufficient USD payment received. Total: \${$expectedTotalUsd}, received: \${$receivedUsd}.",
                        ], 422);
                    }

                    $expectedChangeUsd = round($receivedUsd - $expectedTotalUsd, 2);
                    $expectedChangeRielFromUsd = (int) round($expectedChangeUsd * 4100);

                    // Allow USD change, Riel change, or combined USD + Riel change within rounding margin
                    $isUsdChangeValid = abs($changeUsd - $expectedChangeUsd) <= 0.02;
                    $isRielChangeValid = abs($changeRiel - $expectedChangeRielFromUsd) <= 100;
                    $isCombinedChangeValid = abs(($changeUsd + round($changeRiel / 4100, 2)) - $expectedChangeUsd) <= 0.02;

                    if (!$isUsdChangeValid && !$isRielChangeValid && !$isCombinedChangeValid) {
                        return response()->json([
                            'success' => false,
                            'message' => "USD change mismatch. Expected: \${$expectedChangeUsd} (or {$expectedChangeRielFromUsd} Riel), received: \${$changeUsd} USD / {$changeRiel} Riel.",
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
            if ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry')) {
                $committed = Order::with(['cashier:id,name', 'items'])
                    ->where('client_operation_id', $opId)
                    ->first();
                if ($committed) {
                    return $this->resolveIdempotentOrder($committed, $validated, $user);
                }
            }
            throw $e;
        }
    }
}
