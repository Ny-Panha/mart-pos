<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\InventoryOperation;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MysqlConcurrencyAndIdempotencyTest extends TestCase
{
    protected ?User $cashier = null;
    protected ?User $otherCashier = null;
    protected ?User $admin = null;
    protected ?Category $category = null;
    protected ?Product $product = null;

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we test against the real MySQL connection
        config([
            'database.default' => 'mysql',
            'database.connections.mysql.database' => 'mart_pos_db',
            'database.connections.mysql.username' => 'root',
            'database.connections.mysql.password' => env('DB_PASSWORD', '123456'),
        ]);
        DB::purge('mysql');
        DB::reconnect('mysql');

        // Set up test entities isolated with dedicated test prefixes
        $this->cashier = User::firstOrCreate(
            ['email' => 'mysql_cashier_test@martpos.com'],
            [
                'name' => 'MySQL Cashier Test',
                'role' => 'CASHIER',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->otherCashier = User::firstOrCreate(
            ['email' => 'mysql_other_cashier@martpos.com'],
            [
                'name' => 'MySQL Other Cashier',
                'role' => 'CASHIER',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->admin = User::firstOrCreate(
            ['email' => 'mysql_admin_test@martpos.com'],
            [
                'name' => 'MySQL Admin Test',
                'role' => 'ADMIN',
                'status' => 'active',
                'password' => bcrypt('password123'),
            ]
        );

        $this->category = Category::firstOrCreate(
            ['slug' => 'mysql-concurrency-test-cat'],
            ['name' => 'MySQL Test Cat', 'name_kh' => 'ប្រភេទតេស្ត']
        );

        $this->product = Product::firstOrCreate(
            ['code' => 'MYSQL-TEST-001'],
            [
                'name' => 'MySQL Concurrency Test Product',
                'barcode' => '888000999111',
                'category_id' => $this->category->id,
                'cost_price' => 1500,
                'sale_price' => 2500,
                'stock_qty' => 50,
                'status' => 'active',
            ]
        );
        $this->product->update(['stock_qty' => 50, 'status' => 'active']);
    }

    protected function tearDown(): void
    {
        // Clean up only test records created during this run
        if ($this->product) {
            StockMovement::where('product_id', $this->product->id)->delete();
            OrderItem::where('product_id', $this->product->id)->delete();
            InventoryOperation::where('product_id', $this->product->id)->delete();
        }
        Order::where('client_operation_id', 'like', 'op_mysql_%')->delete();
        InventoryOperation::where('client_operation_id', 'like', 'op_mysql_%')->delete();

        parent::tearDown();
    }

    public function test_mysql_idempotent_checkout_and_concurrency_guards(): void
    {
        $opId = 'op_mysql_order_' . time() . '_' . rand(1000, 9999);
        $initialStock = $this->product->fresh()->stock_qty;

        // 1. Submit original order
        $res1 = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 5]
            ],
            'total_riel' => 12500,
            'received_riel' => 12500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $res1->assertStatus(201)
            ->assertJson(['success' => true]);

        // Stock in MySQL must decrement from 50 to 45
        $this->assertEquals($initialStock - 5, $this->product->fresh()->stock_qty);

        // 2. Submit exact same request (simulating network timeout retry)
        $res2 = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 5]
            ],
            'total_riel' => 12500,
            'received_riel' => 12500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);

        $res2->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Order already processed (idempotent recovery)',
            ]);

        // Stock in MySQL must remain 45, NOT decremented twice!
        $this->assertEquals($initialStock - 5, $this->product->fresh()->stock_qty);

        // 3. Different user attempting to use the same operation ID in MySQL -> 403
        $crossRes = $this->actingAs($this->otherCashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 5]
            ],
            'total_riel' => 12500,
            'received_riel' => 12500,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $crossRes->assertStatus(403);

        // 4. Same user with different payload (tampered quantity or total) -> 409 Conflict
        $conflictRes = $this->actingAs($this->cashier, 'sanctum')->postJson('/api/orders', [
            'client_operation_id' => $opId,
            'items' => [
                ['product_id' => $this->product->id, 'qty' => 10] // Changed qty
            ],
            'total_riel' => 25000,
            'received_riel' => 25000,
            'change_riel' => 0,
            'payment_method' => 'cash_riel',
        ]);
        $conflictRes->assertStatus(409);
    }

    public function test_mysql_inventory_operations_table_enforces_database_uniqueness(): void
    {
        $opId = 'op_mysql_inv_' . time() . '_' . rand(1000, 9999);
        $initialStock = $this->product->fresh()->stock_qty;

        // 1. First Stock In
        $res1 = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 10,
            'note' => 'MySQL shipment',
        ]);
        $res1->assertStatus(200);

        // Verify MySQL database record exists in inventory_operations table
        $this->assertDatabaseHas('inventory_operations', [
            'client_operation_id' => $opId,
            'operation_type' => 'in',
            'product_id' => $this->product->id,
            'qty' => 10,
        ], 'mysql');

        // Stock in MySQL must increase by 10
        $this->assertEquals($initialStock + 10, $this->product->fresh()->stock_qty);

        // 2. Retry identical operation: handled cleanly by DB uniqueness constraint
        $res2 = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 10,
            'note' => 'MySQL shipment',
        ]);
        $res2->assertStatus(200)
            ->assertJson(['message' => 'Stock In already processed (idempotent recovery)']);

        // Stock must remain unchanged on retry
        $this->assertEquals($initialStock + 10, $this->product->fresh()->stock_qty);

        // 3. Retry same operation ID with conflicting parameters -> 409 Conflict
        $resConflict = $this->actingAs($this->admin, 'sanctum')->postJson('/api/inventory/stock-in', [
            'client_operation_id' => $opId,
            'product_id' => $this->product->id,
            'qty' => 999, // Conflicting qty
            'note' => 'Conflicting shipment',
        ]);
        $resConflict->assertStatus(409);
    }
}
