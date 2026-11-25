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

        $totals = (clone $query)->selectRaw(
            'SUM(total_riel) AS riel, SUM(total_usd) AS usd, COUNT(*) AS orders_count'
        )->first();
        $totalSalesRiel = (int) $totals->riel;
        $totalSalesUsd = (float) $totals->usd;
        $totalOrdersCount = (int) $totals->orders_count;

        $totalProfitRiel = (int) OrderItem::whereIn('order_id', $query->select('id'))
            ->selectRaw('SUM((sale_price - cost_price) * qty) as profit')
            ->value('profit');

        $inventory = Product::where('status', 'active')->selectRaw(
            'COUNT(*) AS total, SUM(CASE WHEN stock_qty <= low_stock_threshold THEN 1 ELSE 0 END) AS low_stock'
        )->first();
        $totalProductsCount = (int) $inventory->total;
        $lowStockCount = (int) $inventory->low_stock;

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
