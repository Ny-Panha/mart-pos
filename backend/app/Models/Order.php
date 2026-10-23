<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_number',
        'cashier_id',
        'customer_id',
        'total_riel',
        'total_usd',
        'received_riel',
        'received_usd',
        'change_riel',
        'change_usd',
        'payment_method',
        'status',
        'notes',
    ];

    protected $casts = [
        'total_riel' => 'integer',
        'total_usd' => 'decimal:2',
        'received_riel' => 'integer',
        'received_usd' => 'decimal:2',
        'change_riel' => 'integer',
        'change_usd' => 'decimal:2',
    ];

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
