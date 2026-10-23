<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique();
            $table->string('barcode')->nullable()->index();
            $table->string('sku')->nullable();
            $table->foreignId('category_id')->constrained('categories')->cascadeOnDelete();
            $table->unsignedBigInteger('cost_price')->default(0); // in Riel
            $table->unsignedBigInteger('sale_price')->default(0); // in Riel
            $table->integer('stock_qty')->default(0);
            $table->string('unit')->default('កំប៉ុង');
            $table->integer('low_stock_threshold')->default(5);
            $table->decimal('tax', 5, 2)->default(0.00);
            $table->string('status')->default('active');
            $table->text('image_url')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
