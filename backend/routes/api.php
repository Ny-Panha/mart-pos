<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ReportController;
use Illuminate\Support\Facades\Route;

// Public Auth Route
Route::post('/login', [AuthController::class, 'login']);

// Categories & Products (Publicly viewable for POS UI & Offline/Cache fallback)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{id}', [CategoryController::class, 'show']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/low-stock', [ProductController::class, 'lowStock']);
Route::get('/products/barcode/{barcode}', [ProductController::class, 'findByBarcode']);
Route::get('/products/{id}', [ProductController::class, 'show']);
Route::get('/reports/summary', [ReportController::class, 'summary']);

// Authenticated Routes (Requires Sanctum Token)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Authoritative POS Checkout & Orders
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);

    // Admin/Manager Product Management
    Route::post('/products', [ProductController::class, 'store']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    // Admin/Manager Category Management
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{id}', [CategoryController::class, 'update']);
    Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

    // Authoritative Inventory & Stock Movement Management
    Route::get('/inventory/movements', [InventoryController::class, 'movements']);
    Route::post('/inventory/stock-in', [InventoryController::class, 'stockIn']);
    Route::post('/inventory/stock-out', [InventoryController::class, 'stockOut']);
    Route::post('/inventory/adjust', [InventoryController::class, 'adjustStock']);
    Route::post('/inventory/purchase', [InventoryController::class, 'purchase']);
});
