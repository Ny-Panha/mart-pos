<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('client_operation_id', 64)->nullable()->unique()->after('invoice_number');
            $table->unsignedBigInteger('discount_riel')->default(0)->after('customer_id');
            $table->unsignedBigInteger('tax_riel')->default(0)->after('discount_riel');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['client_operation_id', 'discount_riel', 'tax_riel']);
        });
    }
};
