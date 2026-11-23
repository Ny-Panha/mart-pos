<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with('category')->where('status', 'active');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }

        $products = $query->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $products,
        ]);
    }

    public function show($id)
    {
        $product = Product::with('category')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $product,
        ]);
    }

    public function findByBarcode($barcode)
    {
        $product = Product::with('category')
            ->where('barcode', $barcode)
            ->where('status', 'active')
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found for barcode: ' . $barcode,
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product,
        ]);
    }

    public function lowStock()
    {
        $products = Product::with('category')
            ->where('status', 'active')
            ->whereRaw('stock_qty <= low_stock_threshold')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $products,
        ]);
    }

    public function store(Request $request)
    {
        if ($request->filled('category_id')) {
            $catVal = (string) $request->category_id;
            if (!is_numeric($catVal)) {
                $cleanSlug = str_replace('cat_', '', strtolower(trim($catVal)));
                $foundCat = Category::where('slug', $cleanSlug)
                    ->orWhere('slug', $catVal)
                    ->orWhere('name', $catVal)
                    ->first();
                if ($foundCat) {
                    $request->merge(['category_id' => $foundCat->id]);
                }
            }
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:100|unique:products,code',
            'barcode' => 'nullable|string|max:100',
            'sku' => 'nullable|string|max:100',
            'category_id' => 'required|exists:categories,id',
            'cost_price' => 'required|integer|min:0',
            'sale_price' => 'required|integer|min:0',
            'stock_qty' => 'required|integer|min:0',
            'unit' => 'nullable|string|max:50',
            'low_stock_threshold' => 'nullable|integer|min:0',
            'image_url' => 'nullable|string',
        ]);

        $product = Product::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully',
            'data' => $product->fresh()->load('category'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        if ($request->filled('category_id')) {
            $catVal = (string) $request->category_id;
            if (!is_numeric($catVal)) {
                $cleanSlug = str_replace('cat_', '', strtolower(trim($catVal)));
                $foundCat = Category::where('slug', $cleanSlug)
                    ->orWhere('slug', $catVal)
                    ->orWhere('name', $catVal)
                    ->first();
                if ($foundCat) {
                    $request->merge(['category_id' => $foundCat->id]);
                }
            }
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'sometimes|string|max:100|unique:products,code,' . $product->id,
            'barcode' => 'nullable|string|max:100',
            'sku' => 'nullable|string|max:100',
            'category_id' => 'sometimes|exists:categories,id',
            'cost_price' => 'sometimes|integer|min:0',
            'sale_price' => 'sometimes|integer|min:0',
            'stock_qty' => 'sometimes|integer|min:0',
            'unit' => 'nullable|string|max:50',
            'low_stock_threshold' => 'nullable|integer|min:0',
            'image_url' => 'nullable|string',
            'status' => 'sometimes|string|in:active,inactive',
        ]);

        $product->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data' => $product->fresh()->load('category'),
        ]);
    }

    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        $product->update(['status' => 'inactive']); // Soft deactivation

        return response()->json([
            'success' => true,
            'message' => 'Product removed successfully',
            'data' => $product->fresh(),
        ]);
    }
}
