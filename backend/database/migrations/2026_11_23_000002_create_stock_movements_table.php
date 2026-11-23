<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('type'); // 'in', 'out', 'adjust', 'sale'
            $table->integer('qty'); // positive or negative diff
            $table->integer('stock_before')->default(0);
            $table->integer('stock_after')->default(0);
            $table->text('note')->nullable();
            $table->string('ref_id')->nullable()->index(); // sale invoice, order id, purchase id
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
    }
};
