<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ReportController;
use Illuminate\Support\Facades\Route;

// Public Auth Route
Route::post('/login', [AuthController::class, 'login']);

// Categories & Products (Accessible for POS UI)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/low-stock', [ProductController::class, 'lowStock']);
Route::get('/products/barcode/{barcode}', [ProductController::class, 'findByBarcode']);
Route::get('/products/{id}', [ProductController::class, 'show']);

// POS Orders (Can create order with or without auth token for offline/pos fallback)
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders', [OrderController::class, 'index']);
Route::get('/orders/{id}', [OrderController::class, 'show']);
Route::get('/reports/summary', [ReportController::class, 'summary']);

// Authenticated Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Admin Product Management
    Route::post('/products', [ProductController::class, 'store']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    // Admin Category Management
    Route::post('/categories', [CategoryController::class, 'store']);
});
