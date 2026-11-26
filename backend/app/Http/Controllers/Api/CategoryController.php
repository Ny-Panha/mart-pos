<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::where('status', 'active')
            ->withCount('products')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    public function show($id)
    {
        $category = Category::with('products')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $category,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'name_kh' => 'nullable|string|max:100',
            'slug' => 'nullable|string|max:100|unique:categories,slug',
            'icon' => 'nullable|string|max:50',
        ]);

        $normalizedName = trim($validated['name']);
        $existing = Category::where('status', 'active')
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower($normalizedName)])
            ->first();
        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Category already exists',
                'data' => $existing,
            ], 200);
        }

        $slug = !empty($validated['slug']) ? Str::slug($validated['slug']) : Str::slug($validated['name']);
        if (empty($slug)) {
            $slug = 'cat-' . Str::random(6);
        }

        // Ensure unique slug
        $origSlug = $slug;
        $counter = 1;
        while (Category::where('slug', $slug)->exists()) {
            $slug = $origSlug . '-' . $counter++;
        }

        $category = Category::create([
            'name' => $validated['name'],
            'name_kh' => $validated['name_kh'] ?? $validated['name'],
            'slug' => $slug,
            'icon' => $validated['icon'] ?? 'category',
            'status' => 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Category created successfully',
            'data' => $category,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $category = Category::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'name_kh' => 'nullable|string|max:100',
            'slug' => 'nullable|string|max:100|unique:categories,slug,' . $category->id,
            'icon' => 'nullable|string|max:50',
            'status' => 'sometimes|string|in:active,inactive',
        ]);

        if (isset($validated['name']) && empty($validated['name_kh']) && empty($category->name_kh)) {
            $validated['name_kh'] = $validated['name'];
        }

        $category->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Category updated successfully',
            'data' => $category,
        ]);
    }

    public function destroy($id)
    {
        $category = Category::findOrFail($id);

        if ($category->products()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Category is assigned to products and cannot be deleted.',
            ], 422);
        }

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Category deleted successfully',
        ]);
    }
}
