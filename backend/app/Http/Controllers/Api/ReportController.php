<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function summary(Request $request)
    {
        $today = Carbon::today();
        $startDate = $request->filled('start_date') ? Carbon::parse($request->start_date)->startOfDay() : $today->copy()->startOfDay();
        $endDate = $request->filled('end_date') ? Carbon::parse($request->end_date)->endOfDay() : $today->copy()->endOfDay();

        $query = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('status', 'completed');

        $totalSalesRiel = (int) $query->sum('total_riel');
        $totalSalesUsd = (float) $query->sum('total_usd');
        $totalOrdersCount = (int) $query->count();

        // Calculate authoritative profit from MySQL order items: (sale_price - cost_price) * qty
        $orderIds = (clone $query)->pluck('id');
        $totalProfitRiel = (int) OrderItem::whereIn('order_id', $orderIds)
            ->selectRaw('SUM((sale_price - cost_price) * qty) as profit')
            ->value('profit');

        $lowStockCount = Product::where('status', 'active')
            ->whereRaw('stock_qty <= low_stock_threshold')
            ->count();

        $totalProductsCount = Product::where('status', 'active')->count();

        return response()->json([
            'success' => true,
            'data' => [
                'period' => [
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'total_sales_riel' => $totalSalesRiel,
                    'total_sales_usd' => $totalSalesUsd,
                    'total_orders' => $totalOrdersCount,
                    'total_profit_riel' => $totalProfitRiel,
                ],
                'today' => [
                    'total_sales_riel' => $totalSalesRiel,
                    'total_sales_usd' => $totalSalesUsd,
                    'total_orders' => $totalOrdersCount,
                    'total_profit_riel' => $totalProfitRiel,
                ],
                'inventory' => [
                    'total_products' => $totalProductsCount,
                    'low_stock_count' => $lowStockCount,
                ],
            ],
        ]);
    }
}
