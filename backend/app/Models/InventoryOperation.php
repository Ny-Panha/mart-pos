<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventoryOperation extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_operation_id',
        'operation_type',
        'user_id',
        'product_id',
        'qty',
        'payload_hash',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
        'qty' => 'integer',
        'product_id' => 'integer',
        'user_id' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
