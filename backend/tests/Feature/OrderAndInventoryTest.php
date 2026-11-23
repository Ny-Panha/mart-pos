<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderAndInventoryTest extends TestCase
{
    use RefreshDatabase;

    protected User $cashier;
    protected User $admin;
    protected User $otherCashier;
    protected Category $category;
    protected Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->cashier = User::firstOrCreate(
            ['email' => 'cashier_test@martpos.com'],
            [
                'name' => 'Cashier Test',
                'role' => 'CASHIER',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->otherCashier = User::firstOrCreate(
            ['email' => 'other_cashier@martpos.com'],
            [
                'name' => 'Other Cashier',
                'role' => 'CASHIER',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->admin = User::firstOrCreate(
            ['email' => 'admin_test@martpos.com'],
            [
                'name' => 'Admin Test',
                'role' => 'ADMIN',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->category = Category::firstOrCreate(
            ['slug' => 'test-drinks'],
            ['name' => 'Test Drinks', 'name_kh' => 'ភេសជ្ជៈតេស្ត']
        );

        $this->product = Product::firstOrCreate(
            ['code' => 'TEST-001'],
            [
                'name' => 'Test Energy Drink',
                'barcode' => '999000111',
                'category_id' => $this->category->id,
                'cost_price' => 1500,
                'sale_price' => 2500,
                'stock_qty' => 10,
                'status' => 'active',
            ]
        );
        $this->product->update(['stock_qty' => 10, 'status' => 'active', 'sale_price' => 2500]);
    }

    public function test_checkout_requires_authentication(): void
    {
        $response = $this->postJson('/api/orders', [
            'client_operation_id' => 'op_unauth_checkout_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $response->assertStatus(401);
    }

    public function test_checkout_requires_valid_client_operation_id(): void
    {
        $response = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['client_operation_id']);
    }

    public function test_checkout_rejects_insufficient_stock(): void
    {
        $response = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_reject_stock_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 50] // Requesting 50 when only 10 available
            ],
            'total_riel' => 125000,
            'received_riel' => 125000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        // Verify product stock is untouched
        $this->assertEquals(10, $this->product->fresh()->stock_qty);
    }

    public function test_valid_checkout_deducts_stock_and_creates_stock_movement(): void
    {
        $response = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_valid_checkout_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 3]
            ],
            'total_riel' => 7500,
            'received_riel' => 8000,
            'change_riel' => 500,
            'payment_method' => 'cash_riel',
            'invoice_number' => 'INV-TEST-001',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        // Stock must be 10 - 3 = 7
        $this->assertEquals(7, $this->product->fresh()->stock_qty);

        // Order item must exist
        $this->assertDatabaseHas('orders', [
            'invoice_number' => 'INV-TEST-001',
            'client_operation_id' => 'op_valid_checkout_01',
            'cashier_id' => $this->cashier->id,
            'total_riel' => 7500,
        ]);

        // Stock movement must be recorded
        $this->assertDatabaseHas('stock_movements', [
            'product_id' => $this->product->id,
            'type' => 'sale',
            'qty' => -3,
            'stock_before' => 10,
            'stock_after' => 7,
            'ref_id' => 'INV-TEST-001',
        ]);
    }

    public function test_idempotent_checkout_prevents_duplicate_deduction(): void
    {
        // First request
        $firstResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_idempotency_unique_99',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'received_riel' => 5000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $firstResponse->assertStatus(201);
        $stockAfterFirst = $this->product->fresh()->stock_qty;

        // Second retry with same client_operation_id and same payload
        $retryResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_idempotency_unique_99',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'received_riel' => 5000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        // Must succeed with 200 without error and without cutting stock again
        $retryResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Order already processed (idempotent recovery)',
            ]);

        // Stock must not have changed again
        $this->assertEquals($stockAfterFirst, $this->product->fresh()->stock_qty);
    }

    public function test_checkout_aggregates_multiple_lines_of_same_product(): void
    {
        // Case 1: Line 1 qty 6 + Line 2 qty 5 = total 11 > available 10 -> must reject
        $rejectResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_aggregate_reject_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 6],
                ['product_id' => $this->product->id, 'qty' => 5],
            ],
            'total_riel' => 27500,
            'received_riel' => 27500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $rejectResponse->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
        $this->assertStringContainsString('Insufficient aggregate stock', $rejectResponse->json('message'));
        $this->assertEquals(10, $this->product->fresh()->stock_qty);

        // Case 2: Line 1 qty 2 + Line 2 qty 3 = total 5 <= available 10 -> must succeed
        $acceptResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_aggregate_accept_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2],
                ['product_id' => $this->product->id, 'qty' => 3],
            ],
            'total_riel' => 12500,
            'received_riel' => 13000,
            'change_riel' => 500,
            'payment_method' => 'cash_riel',
        ]);

        $acceptResponse->assertStatus(201);
        // Initial 10 - 5 = 5
        $this->assertEquals(5, $this->product->fresh()->stock_qty);
    }

    public function test_cashier_cannot_apply_discount_or_custom_price(): void
    {
        // 1. Cashier attempts discount
        $discountRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_cashier_discount_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1],
            ],
            'discount_riel' => 500,
            'total_riel' => 2000,
            'received_riel' => 2000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $discountRes->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);

        // 2. Cashier attempts custom price override
        $overrideRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_cashier_override_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1, 'custom_price' => 1800],
            ],
            'total_riel' => 1800,
            'received_riel' => 1800,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $overrideRes->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_admin_can_apply_discount_and_custom_price(): void
    {
        $response = $this->actingAs($this->admin, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_admin_discount_ok_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1, 'custom_price' => 2000],
            ],
            'discount_riel' => 500,
            'total_riel' => 1500, // (2000 custom - 500 discount)
            'received_riel' => 2000,
            'change_riel' => 500,
            'payment_method' => 'cash_riel',
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true]);
    }

    public function test_cross_user_idempotency_key_reuse_is_forbidden(): void
    {
        // Cashier 1 registers order with key
        $res1 = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_cross_user_key_101',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1],
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $res1->assertStatus(201);

        // Cashier 2 tries to reuse the exact same key
        $res2 = $this->actingAs($this->otherCashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_cross_user_key_101',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1],
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $res2->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_idempotent_retry_with_conflicting_payload_fails(): void
    {
        // First order
        $res1 = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_conflict_payload_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1],
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $res1->assertStatus(201);

        // Same cashier, same key, DIFFERENT item quantity and total
        $res2 = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_conflict_payload_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2],
            ],
            'total_riel' => 5000,
            'received_riel' => 5000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $res2->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_cashier_is_forbidden_from_admin_only_routes(): void
    {
        // 1. Reports summary
        $repRes = $this->actingAs($this->cashier, 'sanctum')->getJson('/api/reports/summary');
        $repRes->assertStatus(403);

        // 2. Create product
        $prodRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/products', [
            'name' => 'Cashier Item',
            'code' => 'CASH-999',
            'category_id' => $this->category->id,
            'cost_price' => 100,
            'sale_price' => 200,
            'stock_qty' => 1,
        ]);
        $prodRes->assertStatus(403);

        // 3. Create category
        $catRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/categories', [
            'name' => 'Cashier Cat',
        ]);
        $catRes->assertStatus(403);

        // 4. Adjust inventory
        $adjRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/adjust', [
            'product_id' => $this->product->id,
            'new_qty' => 99,
            'note' => 'Unauthorized adjust',
        ]);
        $adjRes->assertStatus(403);

        // 5. Purchase inventory
        $poRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/purchase', [
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 10],
            ],
        ]);
        $poRes->assertStatus(403);
    }

    public function test_admin_category_management_crud(): void
    {
        // 1. Create category as Admin
        $createRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/categories', [
            'name' => 'Stationery',
        ]);
        $createRes->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'name' => 'Stationery',
                    'slug' => 'stationery',
                ]
            ]);
        $catId = $createRes->json('data.id');

        // 2. Update category as Admin
        $updateRes = $this->actingAs($this->admin, 'sanctum')->putJson("/api/categories/{$catId}", [
            'name' => 'Office Stationery',
        ]);
        $updateRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'name' => 'Office Stationery',
                ]
            ]);

        // 3. Delete category as Admin
        $deleteRes = $this->actingAs($this->admin, 'sanctum')->deleteJson("/api/categories/{$catId}");
        $deleteRes->assertStatus(200)
            ->assertJson(['success' => true]);

        // 4. In-use category delete prevention
        $inUseRes = $this->actingAs($this->admin, 'sanctum')->deleteJson("/api/categories/{$this->category->id}");
        $inUseRes->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_admin_inventory_stock_in_out_adjust_and_purchase_with_idempotency(): void
    {
        $currentStock = $this->product->fresh()->stock_qty;

        // 1. Stock In with operation ID
        $inRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => 'op_stock_in_test_01',
            'product_id' => $this->product->id,
            'qty' => 5,
            'note' => 'Supplier delivery',
        ]);
        $inRes->assertStatus(200);
        $this->assertEquals($currentStock + 5, $this->product->fresh()->stock_qty);

        // 2. Idempotent Retry of Stock In
        $inRetry = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => 'op_stock_in_test_01',
            'product_id' => $this->product->id,
            'qty' => 5,
            'note' => 'Supplier delivery',
        ]);
        $inRetry->assertStatus(200)
            ->assertJson(['message' => 'Stock In already processed (idempotent recovery)']);
        // Stock must not increase twice
        $this->assertEquals($currentStock + 5, $this->product->fresh()->stock_qty);

        // 3. Stock Out
        $outRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-out', [
            'client_operation_id' => 'op_stock_out_test_01',
            'product_id' => $this->product->id,
            'qty' => 2,
            'note' => 'Damaged item',
        ]);
        $outRes->assertStatus(200);
        $this->assertEquals($currentStock + 3, $this->product->fresh()->stock_qty);

        // 4. Stock Out rejects when exceeding available stock
        $overOutRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-out', [
            'product_id' => $this->product->id,
            'qty' => 9999,
            'note' => 'Excessive removal',
        ]);
        $overOutRes->assertStatus(422);

        // 5. Adjust Stock
        $adjRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/adjust', [
            'client_operation_id' => 'op_adjust_test_01',
            'product_id' => $this->product->id,
            'new_qty' => 20,
            'note' => 'Monthly inventory audit count',
        ]);
        $adjRes->assertStatus(200);
        $this->assertEquals(20, $this->product->fresh()->stock_qty);

        // 6. Purchase Order (Multi-item Stock In) with note omitted
        $poRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/purchase', [
            'client_operation_id' => 'op_po_test_01',
            'supplier_name' => 'Coca Cola Cambodia',
            'items' => [
                [
                    'product_id' => $this->product->id,
                    'qty' => 10,
                    'cost_price' => 1400,
                ]
            ],
            // Note omitted
        ]);
        $poRes->assertStatus(201);
        $this->assertEquals(30, $this->product->fresh()->stock_qty);
        $this->assertEquals(1400, $this->product->fresh()->cost_price);

        // 7. Idempotent Retry of Purchase Order
        $poRetry = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/purchase', [
            'client_operation_id' => 'op_po_test_01',
            'items' => [
                [
                    'product_id' => $this->product->id,
                    'qty' => 10,
                    'cost_price' => 1400,
                ]
            ],
        ]);
        $poRetry->assertStatus(200)
            ->assertJson(['message' => 'Purchase already recorded (idempotent recovery)']);
        // Stock must not increase twice
        $this->assertEquals(30, $this->product->fresh()->stock_qty);
    }

    public function test_product_code_update_uniqueness(): void
    {
        $secondProduct = Product::create([
            'name' => 'Second Product',
            'code' => 'TEST-002',
            'category_id' => $this->category->id,
            'cost_price' => 1000,
            'sale_price' => 2000,
            'stock_qty' => 5,
            'status' => 'active',
        ]);

        // 1. Updating second product to an existing code (TEST-001) must fail with 422
        $failRes = $this->actingAs($this->admin, 'sanctum')->putJson("/api/products/{$secondProduct->id}", [
            'code' => 'TEST-001',
        ]);
        $failRes->assertStatus(422)
            ->assertJsonValidationErrors(['code']);

        // 2. Updating second product keeping its own code (TEST-002) must succeed
        $ownRes = $this->actingAs($this->admin, 'sanctum')->putJson("/api/products/{$secondProduct->id}", [
            'code' => 'TEST-002',
            'name' => 'Second Product Renamed',
        ]);
        $ownRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'code' => 'TEST-002',
                    'name' => 'Second Product Renamed',
                ],
            ]);

        // 3. Updating second product to a brand new code must succeed
        $newRes = $this->actingAs($this->admin, 'sanctum')->putJson("/api/products/{$secondProduct->id}", [
            'code' => 'TEST-003',
        ]);
        $newRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'code' => 'TEST-003',
                ],
            ]);
    }

    public function test_find_order_by_operation_id(): void
    {
        // 1. Create order with client_operation_id
        $opId = 'op_lookup_test_888';
        $createRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $createRes->assertStatus(201);

        // 2. Query own operation ID -> 200 OK
        $findRes = $this->actingAs($this->cashier, 'sanctum')->getJson("/api/orders/by-operation/{$opId}");
        $findRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'client_operation_id' => $opId,
                    'total_riel' => 2500,
                ],
            ]);

        // 3. Query non-existent operation ID -> 404
        $notFoundRes = $this->actingAs($this->cashier, 'sanctum')->getJson('/api/orders/by-operation/op_non_existent_999');
        $notFoundRes->assertStatus(404);

        // 4. Query another user's operation ID -> 403 Forbidden
        $crossRes = $this->actingAs($this->otherCashier, 'sanctum')->getJson("/api/orders/by-operation/{$opId}");
        $crossRes->assertStatus(403);
    }

    public function test_tax_calculation_policy_and_limits(): void
    {
        // 1. Valid tax_rate 10% (0.10) with subtotal 2500 -> tax 250 -> total 2750
        $validTaxRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_tax_valid_10pct',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'tax_rate' => 0.10,
            'tax_riel' => 250,
            'total_riel' => 2750,
            'received_riel' => 3000,
            'change_riel' => 250,
            'payment_method' => 'cash_riel',
        ]);
        $validTaxRes->assertStatus(201);

        // 2. Manipulated excessive tax (> 25% policy limit) without tax_rate
        $manipulatedTaxRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_tax_manipulated_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'tax_riel' => 99999, // Absurdly high tax
            'total_riel' => 102499,
            'received_riel' => 102499,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $manipulatedTaxRes->assertStatus(422);

        // 3. Total mismatch where client sends arbitrary total_riel
        $mismatchRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_total_mismatch_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 1000, // Client claimed total is 1000 when subtotal is 2500
            'received_riel' => 1000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $mismatchRes->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_cash_usd_payment_flow_and_rejection_of_unsupported_methods(): void
    {
        // 1. Cash USD supported flow: 2 items @ 2500 = 5000 Riel (or custom 4100 x 2 = 8200 Riel = $2.00)
        // Let's test with 2 items = 5000 Riel, total_usd = 1.22, received $2.00, change $0.78
        $usdRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_usd_checkout_success',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'total_usd' => 1.22,
            'received_usd' => 2.00,
            'change_usd' => 0.78,
            'payment_method' => 'cash_usd',
        ]);
        $usdRes->assertStatus(201);

        // 2. Cash USD with insufficient received amount
        $insufficientUsdRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_usd_insufficient_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'total_usd' => 1.22,
            'received_usd' => 1.00, // Less than $1.22
            'change_usd' => 0.00,
            'payment_method' => 'cash_usd',
        ]);
        $insufficientUsdRes->assertStatus(422);

        // 3. Unsupported payment method (e.g. crypto, bitcoin)
        $unsupportedRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_unsupported_pay_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'payment_method' => 'bitcoin',
        ]);
        $unsupportedRes->assertStatus(422);

        // 4. Cash USD rejecting zero received_usd
        $zeroUsdRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_zero_usd_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'total_usd' => 0.61,
            'received_usd' => 0.00,
            'change_usd' => 0.00,
            'payment_method' => 'cash_usd',
        ]);
        $zeroUsdRes->assertStatus(422);

        // 5. Inconsistent tax rate and tax amount rejection
        $inconsistentTaxRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_inconsistent_tax_fail',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'tax_rate' => 0.10, // 10% on 2500 should be 250
            'tax_riel' => 999, // Manipulated tax
            'total_riel' => 3499,
            'received_riel' => 3499,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $inconsistentTaxRes->assertStatus(422);

        // 6. Consistent tax calculation success
        $consistentTaxRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_consistent_tax_success',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'tax_rate' => 0.10,
            'tax_riel' => 250,
            'total_riel' => 2750,
            'received_riel' => 2750,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $consistentTaxRes->assertStatus(201);
    }

    public function test_inventory_database_idempotency_conflicts_and_ownership(): void
    {
        $opId = 'op_db_idemp_stockin_01';

        // 1. Initial Stock In
        $res1 = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 4,
            'note' => 'Original shipment',
        ]);
        $res1->assertStatus(200);

        // 2. Identical retry returns 200 idempotent recovery
        $res2 = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 4,
            'note' => 'Original shipment',
        ]);
        $res2->assertStatus(200)
            ->assertJson(['message' => 'Stock In already processed (idempotent recovery)']);

        // 3. Retry same operation ID with conflicting quantity -> 409 Conflict
        $conflictQtyRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 10, // Conflicting qty
            'note' => 'Different shipment',
        ]);
        $conflictQtyRes->assertStatus(409);

        // 4. Retry same operation ID with conflicting operation type (stock-out) -> 409 Conflict
        $conflictTypeRes = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-out', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 4,
            'note' => 'Trying to use stock-in op id for stock-out',
        ]);
        $conflictTypeRes->assertStatus(409);
    }

    public function test_authoritative_reports_summary_with_profit(): void
    {
        // 1. Create a sale: product cost_price=1500, sale_price=2500, qty=2 -> profit=(2500-1500)*2 = 2000 Riel
        $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_report_sale_profit_01',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'received_riel' => 5000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ])->assertStatus(201);

        // 2. Fetch authoritative report summary as Admin
        $res = $this->actingAs($this->admin, 'sanctum')->getJson('/api/reports/summary');
        $res->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'period' => [
                        'total_sales_riel',
                        'total_sales_usd',
                        'total_orders',
                        'total_profit_riel',
                    ],
                    'today' => [
                        'total_sales_riel',
                        'total_profit_riel',
                    ],
                    'inventory' => [
                        'total_products',
                        'low_stock_count',
                    ],
                ],
            ]);

        $this->assertGreaterThanOrEqual(5000, $res->json('data.today.total_sales_riel'));
        $this->assertGreaterThanOrEqual(2000, $res->json('data.today.total_profit_riel'));
    }

    public function test_abort_operation_tombstones_operation_and_prevents_commit(): void
    {
        $opId = 'op_abort_test_tombstone_' . uniqid();

        // 1. Authoritative abort before POST arrives
        $abortRes = $this->actingAs($this->cashier, 'sanctum')->postJson("/api/orders/abort-operation/{$opId}");
        $abortRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'aborted' => true,
            ]);

        // 1b. Querying by-operation explicitly returns operation_status: 'cancelled'
        $queryRes = $this->actingAs($this->cashier, 'sanctum')->getJson("/api/orders/by-operation/{$opId}");
        $queryRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'operation_status' => 'cancelled',
                'data' => [
                    'client_operation_id' => $opId,
                    'status' => 'cancelled',
                ],
            ]);

        // 2. An in-flight or delayed POST with this client_operation_id must be rejected with 409 conflict
        $stockBefore = $this->product->fresh()->stock_qty;
        $postRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $postRes->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);

        // Ensure no stock was deducted
        $this->assertEquals($stockBefore, $this->product->fresh()->stock_qty);
    }

    public function test_abort_operation_returns_committed_order_if_already_completed(): void
    {
        $opId = 'op_abort_test_already_committed_' . uniqid();

        // 1. Order commits first
        $postRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'received_riel' => 2500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ])->assertStatus(201);

        $committedInvoice = $postRes->json('data.invoice_number');

        // 2. Abort attempt detects committed order and rejects abort with 409
        $abortRes = $this->actingAs($this->cashier, 'sanctum')->postJson("/api/orders/abort-operation/{$opId}");
        $abortRes->assertStatus(409)
            ->assertJson([
                'success' => false,
                'committed' => true,
            ]);

        $this->assertEquals($committedInvoice, $abortRes->json('data.invoice_number'));
    }
}
