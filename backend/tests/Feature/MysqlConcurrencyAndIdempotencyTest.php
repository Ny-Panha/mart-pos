<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\InventoryOperation;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MysqlConcurrencyAndIdempotencyTest extends TestCase
{
    protected ?User $cashier = null;
    protected ?User $otherCashier = null;
    protected ?User $admin = null;
    protected ?Category $category = null;
    protected ?Product $product = null;
    protected string $runKey = '';

    protected function setUp(): void
    {
        parent::setUp();

        // 1. Strict Fail-Fast Database Safety Check
        $testDb = env('DB_TEST_DATABASE', env('MYSQL_TEST_DATABASE'));
        if (empty($testDb)) {
            throw new \RuntimeException(
                'CRITICAL SAFETY ERROR: Integration tests require an explicitly configured test database (DB_TEST_DATABASE). None provided.'
            );
        }

        $appDb = env('DB_DATABASE', 'mart_pos_db');
        if ($testDb === 'mart_pos_db' || $testDb === $appDb) {
            throw new \RuntimeException(
                "CRITICAL SAFETY ERROR: Refusing to run tests against application database '{$testDb}'. Must use an isolated test database."
            );
        }

        if (!str_ends_with($testDb, '_test') && !str_contains($testDb, '_test_')) {
            throw new \RuntimeException(
                "CRITICAL SAFETY ERROR: Test database '{$testDb}' is not clearly marked as a test database (name must end with '_test'). Aborting."
            );
        }

        // 2. Read connection settings exclusively from environment (NO hardcoded credentials)
        $host = env('DB_TEST_HOST', env('DB_HOST', '127.0.0.1'));
        $port = env('DB_TEST_PORT', env('DB_PORT', '3306'));
        $username = env('DB_TEST_USERNAME', env('DB_USERNAME', 'root'));
        $password = env('DB_TEST_PASSWORD', env('DB_PASSWORD', ''));

        config([
            'database.default' => 'mysql',
            'database.connections.mysql.database' => $testDb,
            'database.connections.mysql.host' => $host,
            'database.connections.mysql.port' => $port,
            'database.connections.mysql.username' => $username,
            'database.connections.mysql.password' => $password,

            // Secondary independent connection to test actual simultaneous database sessions
            'database.connections.mysql_secondary' => [
                'driver' => 'mysql',
                'host' => $host,
                'port' => $port,
                'database' => $testDb,
                'username' => $username,
                'password' => $password,
                'charset' => 'utf8mb4',
                'collation' => 'utf8mb4_unicode_ci',
                'prefix' => '',
                'strict' => true,
            ],
        ]);

        DB::purge('mysql');
        DB::purge('mysql_secondary');
        DB::reconnect('mysql');

        // Ensure test database schema is up-to-date
        Artisan::call('migrate', ['--database' => 'mysql', '--force' => true]);

        // 3. Isolated test fixtures unique to this test run
        $this->runKey = substr(md5(uniqid((string) mt_rand(), true)), 0, 8);

        $this->cashier = User::create([
            'name' => 'Cashier Test ' . $this->runKey,
            'email' => 'cashier_' . $this->runKey . '@martpos-test.com',
            'role' => 'CASHIER',
            'status' => 'active',
            'password' => bcrypt('password123'),
        ]);

        $this->otherCashier = User::create([
            'name' => 'Other Cashier ' . $this->runKey,
            'email' => 'other_' . $this->runKey . '@martpos-test.com',
            'role' => 'CASHIER',
            'status' => 'active',
            'password' => bcrypt('password123'),
        ]);

        $this->admin = User::create([
            'name' => 'Admin Test ' . $this->runKey,
            'email' => 'admin_' . $this->runKey . '@martpos-test.com',
            'role' => 'ADMIN',
            'status' => 'active',
            'password' => bcrypt('password123'),
        ]);

        $this->category = Category::create([
            'slug' => 'cat-' . $this->runKey,
            'name' => 'Test Cat ' . $this->runKey,
            'name_kh' => 'ប្រភេទ ' . $this->runKey,
        ]);

        $this->product = Product::create([
            'code' => 'P-' . $this->runKey,
            'name' => 'Test Product ' . $this->runKey,
            'barcode' => '888' . mt_rand(100000000, 999999999),
            'category_id' => $this->category->id,
            'cost_price' => 1500,
            'sale_price' => 2500,
            'stock_qty' => 50,
            'status' => 'active',
        ]);
    }

    protected function tearDown(): void
    {
        // Safe isolated cleanup targeting ONLY fixtures created during this specific test run
        if ($this->product) {
            StockMovement::where('product_id', $this->product->id)->delete();
            OrderItem::where('product_id', $this->product->id)->delete();
            InventoryOperation::where('product_id', $this->product->id)->delete();
            $this->product->delete();
        }
        if ($this->category) {
            $this->category->delete();
        }
        if ($this->cashier) {
            $orderIds = Order::where('cashier_id', $this->cashier->id)->pluck('id');
            if ($orderIds->isNotEmpty()) {
                OrderItem::whereIn('order_id', $orderIds)->delete();
                Order::whereIn('id', $orderIds)->delete();
            }
            $this->cashier->tokens()->delete();
            $this->cashier->delete();
        }
        if ($this->otherCashier) {
            $orderIds = Order::where('cashier_id', $this->otherCashier->id)->pluck('id');
            if ($orderIds->isNotEmpty()) {
                OrderItem::whereIn('order_id', $orderIds)->delete();
                Order::whereIn('id', $orderIds)->delete();
            }
            $this->otherCashier->tokens()->delete();
            $this->otherCashier->delete();
        }
        if ($this->admin) {
            $this->admin->tokens()->delete();
            $this->admin->delete();
        }

        parent::tearDown();
    }

    public function test_mysql_idempotent_checkout_and_concurrency_guards(): void
    {
        $opId = 'op_mysql_order_' . $this->runKey . '_' . time();
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
                ['product_id' => $this->product->id, 'qty' => 10]
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
        $opId = 'op_mysql_inv_' . $this->runKey . '_' . time();
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
            'qty' => 999,
            'note' => 'Conflicting shipment',
        ]);
        $resConflict->assertStatus(409);
    }

    public function test_mysql_simultaneous_database_operations_with_independent_connections(): void
    {
        $opId = 'op_mysql_simult_' . $this->runKey . '_' . time();

        // Independent connection 1 begins transaction and inserts operation
        $conn1 = DB::connection('mysql');
        $conn2 = DB::connection('mysql_secondary');

        $conn1->beginTransaction();
        try {
            $conn1->table('inventory_operations')->insert([
                'client_operation_id' => $opId,
                'operation_type' => 'in',
                'user_id' => $this->admin->id,
                'product_id' => $this->product->id,
                'qty' => 5,
                'payload_hash' => hash('sha256', 'test_payload'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Commit connection 1 so record is durable in MySQL
            $conn1->commit();
        } catch (\Throwable $e) {
            $conn1->rollBack();
            throw $e;
        }

        // Independent connection 2 (separate session / PDO process) attempts duplicate insert
        $duplicateCaught = false;
        try {
            $conn2->table('inventory_operations')->insert([
                'client_operation_id' => $opId,
                'operation_type' => 'in',
                'user_id' => $this->admin->id,
                'product_id' => $this->product->id,
                'qty' => 5,
                'payload_hash' => hash('sha256', 'test_payload'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (\Illuminate\Database\QueryException $e) {
            // MySQL error 23000 indicates duplicate key constraint violation
            $duplicateCaught = ($e->getCode() === '23000' || str_contains($e->getMessage(), 'Duplicate entry'));
        }

        $this->assertTrue($duplicateCaught, 'Simultaneous duplicate operation on independent connection must be rejected by MySQL UNIQUE constraint.');
    }
}
