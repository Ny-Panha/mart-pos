# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-23 19:45 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)

## Summary: Setup Laravel REST API + MySQL Backend (Teacher Requirements)
1. **Created MySQL Database (`mart_pos_db`)**:
   - Initialized `mart_pos_db` via Laragon MySQL (root / 123456) with utf8mb4 collation.
2. **Setup Laravel 13 Project (`backend/`)**:
   - Initialized Laravel project with MySQL configuration in `backend/.env`.
   - Installed and configured **Laravel Sanctum** (`php artisan install:api`).
3. **Database Migrations & Models**:
   - `users`: Added `role` (ADMIN_MANAGER, ADMIN, CASHIER), `phone`, `status`.
   - `categories`: `id`, `slug`, `name`, `name_kh`, `icon`, `status`.
   - `products`: `id`, `code`, `barcode`, `name`, `category_id`, `cost_price`, `sale_price`, `stock_qty`, `unit`, `low_stock_threshold`.
   - `customers`: `id`, `name`, `phone`, `points`, `debt`.
   - `orders`: `id`, `invoice_number`, `cashier_id`, `total_riel`, `total_usd`, `payment_method`, `status`.
   - `order_items`: `id`, `order_id`, `product_id`, `product_name`, `qty`, `cost_price`, `sale_price`, `subtotal`.
4. **Database Seeder (`DatabaseSeeder.php`)**:
   - Seeded test accounts (`admin@martpos.com`, `cashier@martpos.com` / `password123`).
   - Seeded 4 categories (ភេសជ្ជៈ, នំបុ័ង និងនំចំណី, មី និងអាហារស្រាល, សម្ភារៈប្រើប្រាស់).
   - Seeded 8 realistic mock products with barcodes.
5. **REST API Endpoints Tested & Verified (Port 8080)**:
   - `POST /api/login`: Tested -> Successfully returns Sanctum bearer token.
   - `GET /api/products`: Tested -> Returns product list joined with categories from MySQL.
   - `POST /api/orders`: Tested -> Creates invoice & auto-decrements stock in MySQL transaction.
   - `GET /api/reports/summary`: Tested -> Aggregates daily sales and low-stock count.

## Active Environment
- **Flutter App**: `c:\Users\nhastar\Desktop\Project\mart_pos`
- **Laravel Backend**: `c:\Users\nhastar\Desktop\Project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080` (Running as Daemon background task)
- **MySQL Database**: `mart_pos_db` on `127.0.0.1:3306`

## Next Steps
- Connect Flutter app to call Laravel REST API at `http://localhost:8080/api` (or LAN IP for physical device / emulator).
