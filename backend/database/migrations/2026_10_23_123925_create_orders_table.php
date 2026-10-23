<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('invoice_number')->unique();
            $table->foreignId('cashier_id')->constrained('users');
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->unsignedBigInteger('total_riel')->default(0);
            $table->decimal('total_usd', 10, 2)->default(0.00);
            $table->unsignedBigInteger('received_riel')->default(0);
            $table->decimal('received_usd', 10, 2)->default(0.00);
            $table->unsignedBigInteger('change_riel')->default(0);
            $table->decimal('change_usd', 10, 2)->default(0.00);
            $table->string('payment_method')->default('cash_riel'); // cash_riel, cash_usd, khqr
            $table->string('status')->default('completed'); // completed, hold, cancelled
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
