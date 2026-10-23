<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function summary()
    {
        $today = Carbon::today();

        $todayOrders = Order::whereDate('created_at', $today)->where('status', 'completed');

        $totalSalesRiel = (int) $todayOrders->sum('total_riel');
        $totalSalesUsd = (float) $todayOrders->sum('total_usd');
        $totalOrdersCount = (int) $todayOrders->count();

        $lowStockCount = Product::where('status', 'active')
            ->whereRaw('stock_qty <= low_stock_threshold')
            ->count();

        $totalProductsCount = Product::where('status', 'active')->count();

        return response()->json([
            'success' => true,
            'data' => [
                'today' => [
                    'total_sales_riel' => $totalSalesRiel,
                    'total_sales_usd' => $totalSalesUsd,
                    'total_orders' => $totalOrdersCount,
                ],
                'inventory' => [
                    'total_products' => $totalProductsCount,
                    'low_stock_count' => $lowStockCount,
                ],
            ],
        ]);
    }
}
