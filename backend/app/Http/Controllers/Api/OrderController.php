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

    public function store(Request $request)
    {
        // Must be authenticated cashier, admin, or manager
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated cashier. Please log in.',
            ], 401);
        }

        // Idempotency check: if client_operation_id is sent and order exists, return it
        if ($request->filled('client_operation_id')) {
            $existing = Order::with(['cashier:id,name', 'items'])
                ->where('client_operation_id', $request->client_operation_id)
                ->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Order already processed (idempotent recovery)',
                    'data' => $existing,
                ], 200);
            }
        }

        $validated = $request->validate([
            'client_operation_id' => 'nullable|string|max:64',
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

        return DB::transaction(function () use ($validated, $request, $user) {
            // Concurrent double-request protection with client_operation_id
            if (!empty($validated['client_operation_id'])) {
                $dup = Order::where('client_operation_id', $validated['client_operation_id'])
                    ->lockForUpdate()
                    ->first();
                if ($dup) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Order already processed (idempotent recovery)',
                        'data' => $dup->load(['cashier:id,name', 'items']),
                    ], 200);
                }
            }

            // 1. Strict Stock and Status Verification with Row-Level Locking
            $productsToDeduct = [];
            foreach ($validated['items'] as $itemData) {
                $product = Product::lockForUpdate()->findOrFail($itemData['product_id']);

                if ($product->status !== 'active') {
                    return response()->json([
                        'success' => false,
                        'message' => "Product \"{$product->name}\" is inactive and cannot be sold.",
                    ], 422);
                }

                if ($product->stock_qty < $itemData['qty']) {
                    return response()->json([
                        'success' => false,
                        'message' => "Insufficient stock for \"{$product->name}\". Available: {$product->stock_qty}, requested: {$itemData['qty']}.",
                    ], 422);
                }

                $productsToDeduct[] = [
                    'product' => $product,
                    'qty' => $itemData['qty'],
                    'custom_price' => $itemData['custom_price'] ?? null,
                ];
            }

            // 2. Establish trusted Invoice Number
            $invoiceNumber = $validated['invoice_number'] ?? null;
            if (empty($invoiceNumber) || Order::where('invoice_number', $invoiceNumber)->exists()) {
                $invoiceNumber = 'INV-' . date('Ymd') . '-' . strtoupper(Str::random(5));
            }

            // 3. Create Order
            $order = Order::create([
                'invoice_number' => $invoiceNumber,
                'client_operation_id' => $validated['client_operation_id'] ?? null,
                'cashier_id' => $user->id,
                'customer_id' => $request->customer_id ?? null,
                'discount_riel' => $validated['discount_riel'] ?? 0,
                'tax_riel' => $validated['tax_riel'] ?? 0,
                'total_riel' => $validated['total_riel'],
                'total_usd' => $validated['total_usd'] ?? round($validated['total_riel'] / 4100, 2),
                'received_riel' => $validated['received_riel'] ?? 0,
                'received_usd' => $validated['received_usd'] ?? 0,
                'change_riel' => $validated['change_riel'] ?? 0,
                'change_usd' => $validated['change_usd'] ?? 0,
                'payment_method' => $validated['payment_method'],
                'status' => 'completed',
                'notes' => $validated['notes'] ?? null,
            ]);

            // 4. Process each item, decrement stock, and record stock movement
            foreach ($productsToDeduct as $entry) {
                /** @var Product $product */
                $product = $entry['product'];
                $qty = $entry['qty'];
                $salePrice = $entry['custom_price'] ?? $product->sale_price;
                $subtotal = $salePrice * $qty;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'qty' => $qty,
                    'cost_price' => $product->cost_price,
                    'sale_price' => $salePrice,
                    'subtotal' => $subtotal,
                ]);

                $stockBefore = $product->stock_qty;
                $product->decrement('stock_qty', $qty);
                $stockAfter = $stockBefore - $qty;

                // Authoritative Stock Movement log
                StockMovement::create([
                    'product_id' => $product->id,
                    'type' => 'sale',
                    'qty' => -$qty,
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
    }
}
