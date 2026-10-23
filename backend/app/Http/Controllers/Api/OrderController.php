<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
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
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty' => 'required|integer|min:1',
            'total_riel' => 'required|integer|min:0',
            'total_usd' => 'nullable|numeric|min:0',
            'received_riel' => 'nullable|integer|min:0',
            'received_usd' => 'nullable|numeric|min:0',
            'change_riel' => 'nullable|integer|min:0',
            'change_usd' => 'nullable|numeric|min:0',
            'payment_method' => 'required|string|in:cash_riel,cash_usd,khqr',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $request) {
            $invoiceNumber = 'INV-' . date('Ymd') . '-' . strtoupper(Str::random(5));

            $order = Order::create([
                'invoice_number' => $invoiceNumber,
                'cashier_id' => $request->user() ? $request->user()->id : 1,
                'customer_id' => $request->customer_id ?? null,
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

            foreach ($validated['items'] as $itemData) {
                $product = Product::lockForUpdate()->findOrFail($itemData['product_id']);

                $qty = $itemData['qty'];
                $subtotal = $product->sale_price * $qty;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'qty' => $qty,
                    'cost_price' => $product->cost_price,
                    'sale_price' => $product->sale_price,
                    'subtotal' => $subtotal,
                ]);

                // Auto Cut Stock in MySQL
                $product->decrement('stock_qty', $qty);
            }

            return response()->json([
                'success' => true,
                'message' => 'Order created and stock updated successfully',
                'data' => $order->load(['cashier:id,name', 'items']),
            ], 201);
        });
    }
}
