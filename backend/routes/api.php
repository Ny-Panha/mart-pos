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

// Categories & Products (Publicly viewable for POS catalog & cache fallback)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{id}', [CategoryController::class, 'show']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/low-stock', [ProductController::class, 'lowStock']);
Route::get('/products/barcode/{barcode}', [ProductController::class, 'findByBarcode']);
Route::get('/products/{id}', [ProductController::class, 'show']);

// Authenticated Routes (Requires Sanctum Token)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // POS Checkout & Orders (Accessible to Cashier, Admin, Manager)
    Route::middleware('role:CASHIER,ADMIN,ADMIN_MANAGER')->group(function () {
        Route::post('/orders', [OrderController::class, 'store']);
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/orders/by-operation/{opId}', [OrderController::class, 'findByOperationId']);
        Route::post('/orders/abort-operation/{opId}', [OrderController::class, 'abortOperation']);
        Route::get('/orders/{id}', [OrderController::class, 'show']);
    });

    // Admin & Manager Only: Reports, Product/Category Management, Inventory & Purchases
    Route::middleware('role:ADMIN,ADMIN_MANAGER')->group(function () {
        // Staff / Users List
        Route::get('/users', [AuthController::class, 'users']);

        // Protected Financial & Sales Reports
        Route::get('/reports/summary', [ReportController::class, 'summary']);

        // Product Management
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{id}', [ProductController::class, 'update']);
        Route::delete('/products/{id}', [ProductController::class, 'destroy']);

        // Category Management
        Route::post('/categories', [CategoryController::class, 'store']);
        Route::put('/categories/{id}', [CategoryController::class, 'update']);
        Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

        // Inventory & Purchase Mutations
        Route::get('/inventory/movements', [InventoryController::class, 'movements']);
        Route::post('/inventory/stock-in', [InventoryController::class, 'stockIn']);
        Route::post('/inventory/stock-out', [InventoryController::class, 'stockOut']);
        Route::post('/inventory/adjust', [InventoryController::class, 'adjustStock']);
        Route::post('/inventory/purchase', [InventoryController::class, 'purchase']);
    });
});
