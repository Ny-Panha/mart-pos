<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class InventoryController extends Controller
{
    public function movements(Request $request)
    {
        $query = StockMovement::with(['product:id,name,code,barcode', 'creator:id,name'])
            ->orderBy('created_at', 'desc');

        if ($request->filled('product_id')) {
            $query->where('product_id', $request->product_id);
        }

        $movements = $query->take(100)->get();

        return response()->json([
            'success' => true,
            'data' => $movements,
        ]);
    }

    public function stockIn(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'nullable|string|max:64',
            'product_id' => 'required|exists:products,id',
            'qty' => 'required|integer|min:1',
            'note' => 'nullable|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        // Idempotency check
        if (!empty($validated['client_operation_id'])) {
            $existing = StockMovement::where('ref_id', $validated['client_operation_id'])->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Stock In already processed (idempotent recovery)',
                    'data' => [
                        'product' => Product::findOrFail($validated['product_id']),
                        'movement' => $existing,
                    ],
                ], 200);
            }
        }

        return DB::transaction(function () use ($validated, $user) {
            $product = Product::lockForUpdate()->findOrFail($validated['product_id']);

            $refId = $validated['client_operation_id'] ?? $validated['ref_id'] ?? null;
            if ($refId) {
                $existing = StockMovement::where('ref_id', $refId)->first();
                if ($existing) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Stock In already processed (idempotent recovery)',
                        'data' => [
                            'product' => $product,
                            'movement' => $existing,
                        ],
                    ], 200);
                }
            }

            $stockBefore = $product->stock_qty;
            $product->increment('stock_qty', $validated['qty']);
            $stockAfter = $stockBefore + $validated['qty'];

            $movement = StockMovement::create([
                'product_id' => $product->id,
                'type' => 'in',
                'qty' => $validated['qty'],
                'stock_before' => $stockBefore,
                'stock_after' => $stockAfter,
                'note' => $validated['note'] ?? null,
                'ref_id' => $refId,
                'created_by' => $user ? $user->id : null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Stock In successful',
                'data' => [
                    'product' => $product->fresh(),
                    'movement' => $movement,
                ],
            ], 200);
        });
    }

    public function stockOut(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'nullable|string|max:64',
            'product_id' => 'required|exists:products,id',
            'qty' => 'required|integer|min:1',
            'note' => 'required|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        if (!empty($validated['client_operation_id'])) {
            $existing = StockMovement::where('ref_id', $validated['client_operation_id'])->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Stock Out already processed (idempotent recovery)',
                    'data' => [
                        'product' => Product::findOrFail($validated['product_id']),
                        'movement' => $existing,
                    ],
                ], 200);
            }
        }

        return DB::transaction(function () use ($validated, $user) {
            $product = Product::lockForUpdate()->findOrFail($validated['product_id']);

            $refId = $validated['client_operation_id'] ?? $validated['ref_id'] ?? null;
            if ($refId) {
                $existing = StockMovement::where('ref_id', $refId)->first();
                if ($existing) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Stock Out already processed (idempotent recovery)',
                        'data' => [
                            'product' => $product,
                            'movement' => $existing,
                        ],
                    ], 200);
                }
            }

            if ($product->stock_qty < $validated['qty']) {
                return response()->json([
                    'success' => false,
                    'message' => "Insufficient stock. Available: {$product->stock_qty}, requested: {$validated['qty']}.",
                ], 422);
            }

            $stockBefore = $product->stock_qty;
            $product->decrement('stock_qty', $validated['qty']);
            $stockAfter = $stockBefore - $validated['qty'];

            $movement = StockMovement::create([
                'product_id' => $product->id,
                'type' => 'out',
                'qty' => -$validated['qty'],
                'stock_before' => $stockBefore,
                'stock_after' => $stockAfter,
                'note' => $validated['note'],
                'ref_id' => $refId,
                'created_by' => $user ? $user->id : null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Stock Out successful',
                'data' => [
                    'product' => $product->fresh(),
                    'movement' => $movement,
                ],
            ], 200);
        });
    }

    public function adjustStock(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'nullable|string|max:64',
            'product_id' => 'required|exists:products,id',
            'new_qty' => 'required|integer|min:0',
            'note' => 'required|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        if (!empty($validated['client_operation_id'])) {
            $existing = StockMovement::where('ref_id', $validated['client_operation_id'])->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Stock adjusted already (idempotent recovery)',
                    'data' => [
                        'product' => Product::findOrFail($validated['product_id']),
                        'movement' => $existing,
                    ],
                ], 200);
            }
        }

        return DB::transaction(function () use ($validated, $user) {
            $product = Product::lockForUpdate()->findOrFail($validated['product_id']);

            $refId = $validated['client_operation_id'] ?? $validated['ref_id'] ?? null;
            if ($refId) {
                $existing = StockMovement::where('ref_id', $refId)->first();
                if ($existing) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Stock adjusted already (idempotent recovery)',
                        'data' => [
                            'product' => $product,
                            'movement' => $existing,
                        ],
                    ], 200);
                }
            }

            $stockBefore = $product->stock_qty;
            $newQty = $validated['new_qty'];
            $diff = $newQty - $stockBefore;

            $product->update(['stock_qty' => $newQty]);

            $movement = StockMovement::create([
                'product_id' => $product->id,
                'type' => 'adjust',
                'qty' => $diff,
                'stock_before' => $stockBefore,
                'stock_after' => $newQty,
                'note' => $validated['note'],
                'ref_id' => $refId,
                'created_by' => $user ? $user->id : null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Stock adjusted successfully',
                'data' => [
                    'product' => $product->fresh(),
                    'movement' => $movement,
                ],
            ], 200);
        });
    }

    public function purchase(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'nullable|string|max:64',
            'supplier_name' => 'nullable|string|max:255',
            'supplier_id' => 'nullable|string|max:100',
            'note' => 'nullable|string|max:500',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.cost_price' => 'nullable|integer|min:0',
        ]);

        $opId = $validated['client_operation_id'] ?? null;
        if (!empty($opId)) {
            $existing = StockMovement::where('ref_id', $opId)->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Purchase already recorded (idempotent recovery)',
                    'data' => [
                        'ref_id' => $opId,
                        'products' => Product::whereIn('id', array_column($validated['items'], 'product_id'))->get(),
                    ],
                ], 200);
            }
        }

        return DB::transaction(function () use ($validated, $user, $opId) {
            $refId = $opId ?? ('PO-' . date('Ymd') . '-' . strtoupper(Str::random(5)));

            if ($opId) {
                $existing = StockMovement::where('ref_id', $opId)->first();
                if ($existing) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Purchase already recorded (idempotent recovery)',
                        'data' => [
                            'ref_id' => $refId,
                            'products' => Product::whereIn('id', array_column($validated['items'], 'product_id'))->get(),
                        ],
                    ], 200);
                }
            }

            $updatedProducts = [];

            foreach ($validated['items'] as $itemData) {
                $product = Product::lockForUpdate()->findOrFail($itemData['product_id']);
                $stockBefore = $product->stock_qty;
                $qty = $itemData['qty'];

                $updateData = ['stock_qty' => $stockBefore + $qty];
                if (isset($itemData['cost_price']) && $itemData['cost_price'] >= 0) {
                    $updateData['cost_price'] = $itemData['cost_price'];
                }
                $product->update($updateData);

                // Fix: Safely check if 'note' is set in $validated without throwing Undefined array key warning
                $noteSuffix = (!empty($validated['note']) ? ' - ' . $validated['note'] : '');
                $supplierStr = $validated['supplier_name'] ?? 'Supplier';

                StockMovement::create([
                    'product_id' => $product->id,
                    'type' => 'in',
                    'qty' => $qty,
                    'stock_before' => $stockBefore,
                    'stock_after' => $stockBefore + $qty,
                    'note' => 'Purchase: ' . $supplierStr . $noteSuffix,
                    'ref_id' => $refId,
                    'created_by' => $user ? $user->id : null,
                ]);

                $updatedProducts[] = $product->fresh();
            }

            return response()->json([
                'success' => true,
                'message' => 'Purchase recorded and stock added successfully in MySQL',
                'data' => [
                    'ref_id' => $refId,
                    'products' => $updatedProducts,
                ],
            ], 201);
        });
    }
}
