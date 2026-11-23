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
        // Reset stock to 10 for consistency
        $this->product->update(['stock_qty' => 10, 'status' => 'active']);
    }

    public function test_checkout_requires_authentication(): void
    {
        $response = $this->postJson('/api/orders', [
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 1]
            ],
            'total_riel' => 2500,
            'payment_method' => 'cash_riel',
        ]);

        $response->assertStatus(401);
    }

    public function test_checkout_rejects_insufficient_stock(): void
    {
        $response = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 50] // Requesting 50 when only 10 available
            ],
            'total_riel' => 125000,
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
            'client_operation_id' => 'op_test_123',
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
            'client_operation_id' => 'op_test_123',
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
        // First request already processed in previous test or process now
        $firstResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_idempotency_unique_99',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'payment_method' => 'cash_riel',
        ]);
        $firstResponse->assertStatus(201);
        $stockAfterFirst = $this->product->fresh()->stock_qty;

        // Second retry with same client_operation_id
        $retryResponse = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => 'op_idempotency_unique_99',
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 2]
            ],
            'total_riel' => 5000,
            'payment_method' => 'cash_riel',
        ]);

        // Must succeed without error and without cutting stock again
        $retryResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Order already processed (idempotent recovery)',
            ]);

        // Stock must not have changed again
        $this->assertEquals($stockAfterFirst, $this->product->fresh()->stock_qty);
    }

    public function test_category_management_crud(): void
    {
        // 1. Create category
        $createRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/categories', [
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

        // 2. Update category
        $updateRes = $this->actingAs($this->cashier, 'sanctum')->putJson("/api/categories/{$catId}", [
            'name' => 'Office Stationery',
        ]);
        $updateRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'name' => 'Office Stationery',
                ]
            ]);

        // 3. Delete category
        $deleteRes = $this->actingAs($this->cashier, 'sanctum')->deleteJson("/api/categories/{$catId}");
        $deleteRes->assertStatus(200)
            ->assertJson(['success' => true]);

        // 4. In-use category delete prevention
        $inUseRes = $this->actingAs($this->cashier, 'sanctum')->deleteJson("/api/categories/{$this->category->id}");
        $inUseRes->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_inventory_stock_in_out_adjust(): void
    {
        $currentStock = $this->product->fresh()->stock_qty;

        // 1. Stock In
        $inRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/stock-in', [
            'product_id' => $this->product->id,
            'qty' => 5,
            'note' => 'Supplier delivery',
        ]);
        $inRes->assertStatus(200);
        $this->assertEquals($currentStock + 5, $this->product->fresh()->stock_qty);

        // 2. Stock Out
        $outRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/stock-out', [
            'product_id' => $this->product->id,
            'qty' => 2,
            'note' => 'Damaged item',
        ]);
        $outRes->assertStatus(200);
        $this->assertEquals($currentStock + 3, $this->product->fresh()->stock_qty);

        // 3. Stock Out rejects when exceeding available stock
        $overOutRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/stock-out', [
            'product_id' => $this->product->id,
            'qty' => 9999,
            'note' => 'Excessive removal',
        ]);
        $overOutRes->assertStatus(422);

        // 4. Adjust Stock
        $adjRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/adjust', [
            'product_id' => $this->product->id,
            'new_qty' => 20,
            'note' => 'Monthly inventory audit count',
        ]);
        $adjRes->assertStatus(200);
        $this->assertEquals(20, $this->product->fresh()->stock_qty);

        // 5. Purchase Order (Multi-item Stock In)
        $poRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/inventory/purchase', [
            'supplier_name' => 'Coca Cola Cambodia',
            'items' => [
                [
                    'product_id' => $this->product->id,
                    'qty' => 10,
                    'cost_price' => 1400,
                ]
            ],
            'note' => 'Weekly restocking',
        ]);
        $poRes->assertStatus(201);
        $this->assertEquals(30, $this->product->fresh()->stock_qty);
        $this->assertEquals(1400, $this->product->fresh()->cost_price);
    }
}
