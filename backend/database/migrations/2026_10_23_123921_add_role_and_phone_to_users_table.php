<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('CASHIER')->after('email'); // ADMIN_MANAGER, ADMIN, CASHIER
            $table->string('phone')->nullable()->after('role');
            $table->string('status')->default('active')->after('phone');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'phone', 'status']);
        });
    }
};
