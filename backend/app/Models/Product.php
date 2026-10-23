<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'barcode',
        'sku',
        'category_id',
        'cost_price',
        'sale_price',
        'stock_qty',
        'unit',
        'low_stock_threshold',
        'tax',
        'status',
        'image_url',
    ];

    protected $casts = [
        'cost_price' => 'integer',
        'sale_price' => 'integer',
        'stock_qty' => 'integer',
        'low_stock_threshold' => 'integer',
        'tax' => 'decimal:2',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }
}
