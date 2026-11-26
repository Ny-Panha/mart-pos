<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryOperation;
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

    private function resolveIdempotentInventoryOperation(
        InventoryOperation $existingOp,
        string $expectedType,
        ?int $productId,
        ?int $qty,
        $user,
        ?string $payloadHash = null
    ): \Illuminate\Http\JsonResponse {
        // Enforce user ownership
        if ($existingOp->user_id !== null && $user && $existingOp->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Cross-user idempotency violation: Operation ID is registered to another user.',
            ], 403);
        }

        // Enforce operation type
        if ($existingOp->operation_type !== $expectedType) {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: client_operation_id already used with a different operation type.',
            ], 409);
        }

        // Enforce product
        if ($productId !== null && $existingOp->product_id !== null && $existingOp->product_id !== $productId) {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: client_operation_id already used with a different product.',
            ], 409);
        }

        // Enforce quantity
        if ($qty !== null && $existingOp->qty !== null && $existingOp->qty !== $qty) {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: client_operation_id already used with different quantity.',
            ], 409);
        }

        // Enforce payload hash
        if ($payloadHash !== null && $existingOp->payload_hash !== null && $existingOp->payload_hash !== $payloadHash) {
            return response()->json([
                'success' => false,
                'message' => 'Conflict: client_operation_id already used with different payload.',
            ], 409);
        }

        if ($expectedType === 'purchase') {
            $productIds = $existingOp->metadata['product_ids'] ?? [];
            return response()->json([
                'success' => true,
                'message' => 'Purchase already recorded (idempotent recovery)',
                'data' => [
                    'ref_id' => $existingOp->client_operation_id,
                    'products' => Product::whereIn('id', $productIds)->get(),
                ],
            ], 200);
        }

        $movement = StockMovement::where('ref_id', $existingOp->client_operation_id)->first();
        $product = Product::find($existingOp->product_id);

        $actionWord = $expectedType === 'in' ? 'Stock In' : ($expectedType === 'out' ? 'Stock Out' : 'Stock adjusted');
        return response()->json([
            'success' => true,
            'message' => "{$actionWord} already processed (idempotent recovery)",
            'data' => [
                'product' => $product,
                'movement' => $movement,
            ],
        ], 200);
    }

    public function stockIn(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'required|string|min:8|max:64',
            'product_id' => 'required|exists:products,id',
            'qty' => 'required|integer|min:1',
            'note' => 'nullable|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        $opId = $validated['client_operation_id'];
        $payloadHash = hash('sha256', "in:{$validated['product_id']}:{$validated['qty']}");

        $existingOp = InventoryOperation::where('client_operation_id', $opId)->first();
        if ($existingOp) {
            return $this->resolveIdempotentInventoryOperation(
                $existingOp, 'in', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
            );
        }

        try {
            return DB::transaction(function () use ($validated, $user, $opId, $payloadHash) {
                $dup = InventoryOperation::where('client_operation_id', $opId)->lockForUpdate()->first();
                if ($dup) {
                    return $this->resolveIdempotentInventoryOperation(
                        $dup, 'in', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
                    );
                }

                $product = Product::lockForUpdate()->findOrFail($validated['product_id']);
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
                    'ref_id' => $opId,
                    'created_by' => $user ? $user->id : null,
                ]);

                InventoryOperation::create([
                    'client_operation_id' => $opId,
                    'operation_type' => 'in',
                    'user_id' => $user ? $user->id : null,
                    'product_id' => $product->id,
                    'qty' => $validated['qty'],
                    'payload_hash' => $payloadHash,
                    'metadata' => ['note' => $validated['note'] ?? null],
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
        } catch (\Illuminate\Database\QueryException $e) {
            if ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry')) {
                $committed = InventoryOperation::where('client_operation_id', $opId)->first();
                if ($committed) {
                    return $this->resolveIdempotentInventoryOperation(
                        $committed, 'in', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
                    );
                }
            }
            throw $e;
        }
    }

    public function stockOut(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'required|string|min:8|max:64',
            'product_id' => 'required|exists:products,id',
            'qty' => 'required|integer|min:1',
            'note' => 'required|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        $opId = $validated['client_operation_id'];
        $payloadHash = hash('sha256', "out:{$validated['product_id']}:{$validated['qty']}");

        $existingOp = InventoryOperation::where('client_operation_id', $opId)->first();
        if ($existingOp) {
            return $this->resolveIdempotentInventoryOperation(
                $existingOp, 'out', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
            );
        }

        try {
            return DB::transaction(function () use ($validated, $user, $opId, $payloadHash) {
                $dup = InventoryOperation::where('client_operation_id', $opId)->lockForUpdate()->first();
                if ($dup) {
                    return $this->resolveIdempotentInventoryOperation(
                        $dup, 'out', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
                    );
                }

                $product = Product::lockForUpdate()->findOrFail($validated['product_id']);

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
                    'ref_id' => $opId,
                    'created_by' => $user ? $user->id : null,
                ]);

                InventoryOperation::create([
                    'client_operation_id' => $opId,
                    'operation_type' => 'out',
                    'user_id' => $user ? $user->id : null,
                    'product_id' => $product->id,
                    'qty' => $validated['qty'],
                    'payload_hash' => $payloadHash,
                    'metadata' => ['note' => $validated['note']],
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
        } catch (\Illuminate\Database\QueryException $e) {
            if ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry')) {
                $committed = InventoryOperation::where('client_operation_id', $opId)->first();
                if ($committed) {
                    return $this->resolveIdempotentInventoryOperation(
                        $committed, 'out', (int) $validated['product_id'], (int) $validated['qty'], $user, $payloadHash
                    );
                }
            }
            throw $e;
        }
    }

    public function adjustStock(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'required|string|min:8|max:64',
            'product_id' => 'required|exists:products,id',
            'new_qty' => 'required|integer|min:0',
            'note' => 'required|string|max:500',
            'ref_id' => 'nullable|string|max:100',
        ]);

        $opId = $validated['client_operation_id'];
        $payloadHash = hash('sha256', "adjust:{$validated['product_id']}:{$validated['new_qty']}");

        $existingOp = InventoryOperation::where('client_operation_id', $opId)->first();
        if ($existingOp) {
            return $this->resolveIdempotentInventoryOperation(
                $existingOp, 'adjust', (int) $validated['product_id'], (int) $validated['new_qty'], $user, $payloadHash
            );
        }

        try {
            return DB::transaction(function () use ($validated, $user, $opId, $payloadHash) {
                $dup = InventoryOperation::where('client_operation_id', $opId)->lockForUpdate()->first();
                if ($dup) {
                    return $this->resolveIdempotentInventoryOperation(
                        $dup, 'adjust', (int) $validated['product_id'], (int) $validated['new_qty'], $user, $payloadHash
                    );
                }

                $product = Product::lockForUpdate()->findOrFail($validated['product_id']);
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
                    'ref_id' => $opId,
                    'created_by' => $user ? $user->id : null,
                ]);

                InventoryOperation::create([
                    'client_operation_id' => $opId,
                    'operation_type' => 'adjust',
                    'user_id' => $user ? $user->id : null,
                    'product_id' => $product->id,
                    'qty' => $newQty,
                    'payload_hash' => $payloadHash,
                    'metadata' => ['note' => $validated['note']],
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
        } catch (\Illuminate\Database\QueryException $e) {
            if ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry')) {
                $committed = InventoryOperation::where('client_operation_id', $opId)->first();
                if ($committed) {
                    return $this->resolveIdempotentInventoryOperation(
                        $committed, 'adjust', (int) $validated['product_id'], (int) $validated['new_qty'], $user, $payloadHash
                    );
                }
            }
            throw $e;
        }
    }

    public function purchase(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'client_operation_id' => 'required|string|min:8|max:64',
            'supplier_name' => 'nullable|string|max:255',
            'supplier_id' => 'nullable|string|max:100',
            'note' => 'nullable|string|max:500',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.cost_price' => 'nullable|integer|min:0',
        ]);

        $opId = $validated['client_operation_id'];
        $itemsSummary = array_map(function ($i) {
            return [
                'p' => (int) $i['product_id'],
                'q' => (int) $i['qty'],
                'c' => (int) ($i['cost_price'] ?? 0),
            ];
        }, $validated['items']);
        usort($itemsSummary, fn($a, $b) => $a['p'] <=> $b['p']);
        $payloadHash = hash('sha256', json_encode($itemsSummary));

        $existingOp = InventoryOperation::where('client_operation_id', $opId)->first();
        if ($existingOp) {
            return $this->resolveIdempotentInventoryOperation(
                $existingOp, 'purchase', null, null, $user, $payloadHash
            );
        }

        try {
            return DB::transaction(function () use ($validated, $user, $opId, $payloadHash) {
                $dup = InventoryOperation::where('client_operation_id', $opId)->lockForUpdate()->first();
                if ($dup) {
                    return $this->resolveIdempotentInventoryOperation(
                        $dup, 'purchase', null, null, $user, $payloadHash
                    );
                }

                $updatedProducts = [];
                $productIds = [];

                // Sort items by product ID to avoid deadlocks
                $sortedItems = $validated['items'];
                usort($sortedItems, fn($a, $b) => (int) $a['product_id'] <=> (int) $b['product_id']);

                foreach ($sortedItems as $itemData) {
                    $product = Product::lockForUpdate()->findOrFail($itemData['product_id']);
                    $stockBefore = $product->stock_qty;
                    $qty = $itemData['qty'];

                    $updateData = ['stock_qty' => $stockBefore + $qty];
                    if (isset($itemData['cost_price']) && $itemData['cost_price'] >= 0) {
                        $updateData['cost_price'] = $itemData['cost_price'];
                    }
                    $product->update($updateData);

                    $noteSuffix = (!empty($validated['note']) ? ' - ' . $validated['note'] : '');
                    $supplierStr = $validated['supplier_name'] ?? 'Supplier';

                    StockMovement::create([
                        'product_id' => $product->id,
                        'type' => 'in',
                        'qty' => $qty,
                        'stock_before' => $stockBefore,
                        'stock_after' => $stockBefore + $qty,
                        'note' => 'Purchase: ' . $supplierStr . $noteSuffix,
                        'ref_id' => $opId,
                        'created_by' => $user ? $user->id : null,
                    ]);

                    $updatedProducts[] = $product->fresh();
                    $productIds[] = $product->id;
                }

                InventoryOperation::create([
                    'client_operation_id' => $opId,
                    'operation_type' => 'purchase',
                    'user_id' => $user ? $user->id : null,
                    'product_id' => null,
                    'qty' => null,
                    'payload_hash' => $payloadHash,
                    'metadata' => [
                        'supplier_name' => $validated['supplier_name'] ?? null,
                        'product_ids' => $productIds,
                    ],
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Purchase recorded and stock added successfully in MySQL',
                    'data' => [
                        'ref_id' => $opId,
                        'products' => $updatedProducts,
                    ],
                ], 201);
            });
        } catch (\Illuminate\Database\QueryException $e) {
            if ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry')) {
                $committed = InventoryOperation::where('client_operation_id', $opId)->first();
                if ($committed) {
                    return $this->resolveIdempotentInventoryOperation(
                        $committed, 'purchase', null, null, $user, $payloadHash
                    );
                }
            }
            throw $e;
        }
    }

    public function purchases()
    {
        $movements = StockMovement::with(['product:id,name,cost_price', 'creator:id,name'])
            ->where('type', 'in')
            ->where('ref_id', 'like', 'op_po_%')
            ->orderByDesc('created_at')
            ->limit(200)
            ->get();

        $opsByRef = InventoryOperation::whereIn('client_operation_id', $movements->pluck('ref_id')->unique()->values())
            ->get()
            ->keyBy('client_operation_id');

        $grouped = [];
        foreach ($movements as $m) {
            $refId = $m->ref_id ?: ('po_' . $m->id);
            if (!isset($grouped[$refId])) {
                $op = $opsByRef->get($refId);
                $meta = is_array($op?->metadata) ? $op->metadata : [];
                $supplierName = $meta['supplier_name'] ?? '';
                $noteText = null;
                $rawNote = (string) ($m->note ?? '');
                if (str_starts_with($rawNote, 'Purchase: ')) {
                    $rest = substr($rawNote, strlen('Purchase: '));
                    $parts = explode(' - ', $rest, 2);
                    if (empty($supplierName)) {
                        $supplierName = trim($parts[0]);
                    }
                    if (count($parts) > 1 && trim($parts[1]) !== '') {
                        $noteText = trim($parts[1]);
                    }
                } elseif ($rawNote !== '') {
                    $noteText = $rawNote;
                }

                $grouped[$refId] = [
                    'id' => preg_replace('/^op_/', '', $refId),
                    'supplier_id' => (string) ($meta['supplier_id'] ?? ''),
                    'supplier_name' => $supplierName !== '' ? $supplierName : 'Supplier',
                    'note' => $noteText,
                    'created_by' => $m->creator?->name ?? (string) ($m->created_by ?? 'Admin'),
                    'created_at' => optional($m->created_at)->toIso8601String(),
                    'total_cost' => 0,
                    'items' => [],
                ];
            }

            $costPrice = (int) ($m->product?->cost_price ?? 0);
            $qty = (int) $m->qty;
            $grouped[$refId]['items'][] = [
                'product_id' => (string) $m->product_id,
                'name' => $m->product?->name ?? ('Product #' . $m->product_id),
                'qty' => $qty,
                'cost_price' => $costPrice,
            ];
            $grouped[$refId]['total_cost'] += $qty * $costPrice;
        }

        return response()->json([
            'success' => true,
            'data' => array_values($grouped),
        ]);
    }
}
