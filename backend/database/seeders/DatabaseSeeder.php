<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Customer;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Users
        $admin = User::firstOrCreate(
            ['email' => 'admin@martpos.com'],
            [
                'name' => 'Admin Manager',
                'role' => 'ADMIN_MANAGER',
                'phone' => '012345678',
                'status' => 'active',
                'password' => Hash::make('password123'),
            ]
        );

        $cashier = User::firstOrCreate(
            ['email' => 'cashier@martpos.com'],
            [
                'name' => 'Nha Cashier',
                'role' => 'CASHIER',
                'phone' => '098765432',
                'status' => 'active',
                'password' => Hash::make('password123'),
            ]
        );

        // 2. Customers
        Customer::firstOrCreate(
            ['phone' => '012999888'],
            [
                'name' => 'អតិថិជនទូទៅ (Walk-in)',
                'points' => 0,
                'debt' => 0,
            ]
        );

        // 3. Categories
        $catDrinks = Category::firstOrCreate(
            ['slug' => 'drinks'],
            ['name' => 'Beverages', 'name_kh' => 'ភេសជ្ជៈ', 'icon' => 'local_drink']
        );

        $catSnacks = Category::firstOrCreate(
            ['slug' => 'snacks'],
            ['name' => 'Snacks & Bakery', 'name_kh' => 'នំបុ័ង និងនំចំណី', 'icon' => 'bakery_dining']
        );

        $catFood = Category::firstOrCreate(
            ['slug' => 'food'],
            ['name' => 'Instant Food', 'name_kh' => 'មី និងអាហារស្រាល', 'icon' => 'ramen_dining']
        );

        $catDaily = Category::firstOrCreate(
            ['slug' => 'daily'],
            ['name' => 'Daily Utilities', 'name_kh' => 'សម្ភារៈប្រើប្រាស់', 'icon' => 'shopping_bag']
        );

        // 4. Products
        $products = [
            [
                'code' => 'PROD-001',
                'barcode' => '884000101',
                'sku' => 'COCA-330',
                'name' => 'Coca Cola 330ml',
                'category_id' => $catDrinks->id,
                'cost_price' => 1600,
                'sale_price' => 2500,
                'stock_qty' => 48,
                'unit' => 'កំប៉ុង',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/coca_cola.jpg',
            ],
            [
                'code' => 'PROD-002',
                'barcode' => '884000102',
                'sku' => 'STING-330',
                'name' => 'Sting Energy Drink 330ml',
                'category_id' => $catDrinks->id,
                'cost_price' => 1800,
                'sale_price' => 3000,
                'stock_qty' => 36,
                'unit' => 'ដប',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/sting_energy.jpg',
            ],
            [
                'code' => 'PROD-003',
                'barcode' => '884000103',
                'sku' => 'REDBULL-250',
                'name' => 'Red Bull Energy 250ml',
                'category_id' => $catDrinks->id,
                'cost_price' => 2400,
                'sale_price' => 3600,
                'stock_qty' => 24,
                'unit' => 'កំប៉ុង',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/red_bull.jpg',
            ],
            [
                'code' => 'PROD-004',
                'barcode' => '884000104',
                'sku' => 'CARABAO-250',
                'name' => 'Carabao Energy 250ml',
                'category_id' => $catDrinks->id,
                'cost_price' => 1600,
                'sale_price' => 2500,
                'stock_qty' => 30,
                'unit' => 'កំប៉ុង',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/carabao.jpg',
            ],
            [
                'code' => 'PROD-005',
                'barcode' => '884000105',
                'sku' => 'WATER-500',
                'name' => 'Pure Drinking Water 500ml',
                'category_id' => $catDrinks->id,
                'cost_price' => 600,
                'sale_price' => 1000,
                'stock_qty' => 60,
                'unit' => 'ដប',
                'low_stock_threshold' => 15,
                'image_url' => 'assets/products/water.jpg',
            ],
            [
                'code' => 'PROD-006',
                'barcode' => '884000106',
                'sku' => 'MAMA-TOMYUM',
                'name' => 'Mama Instant Noodles Tom Yum',
                'category_id' => $catFood->id,
                'cost_price' => 1000,
                'sale_price' => 1500,
                'stock_qty' => 50,
                'unit' => 'កញ្ចប់',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/mama.jpg',
            ],
            [
                'code' => 'PROD-007',
                'barcode' => '884000107',
                'sku' => 'INDOMIE-GORENG',
                'name' => 'Indomie Mi Goreng 85g',
                'category_id' => $catFood->id,
                'cost_price' => 1300,
                'sale_price' => 2000,
                'stock_qty' => 45,
                'unit' => 'កញ្ចប់',
                'low_stock_threshold' => 10,
                'image_url' => 'assets/products/indomie.jpg',
            ],
            [
                'code' => 'PROD-008',
                'barcode' => '884000108',
                'sku' => 'LAYS-CLASSIC',
                'name' => 'Lays Classic Potato Chips 50g',
                'category_id' => $catSnacks->id,
                'cost_price' => 2800,
                'sale_price' => 4000,
                'stock_qty' => 20,
                'unit' => 'កញ្ចប់',
                'low_stock_threshold' => 5,
                'image_url' => 'assets/products/lays.jpg',
            ],
        ];

        foreach ($products as $p) {
            Product::firstOrCreate(
                ['code' => $p['code']],
                $p
            );
        }
    }
}
