# 🏪 ឯកសារត្រៀមការពារគម្រោង & Demo (Project Defense Guide)
**គម្រោង៖** ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart POS & Inventory System)  
**និស្សិត៖** នី បញ្ញា (Build Bright University - Year 4, Semester 2)

---

## 💡 គន្លឹះឆ្លើយពេលឡើងការពារ ឬ Demo បង្ហាញគ្រូ (បានពិន្ទុពេញ)

### 1. ពេលគ្រូឱ្យបង្ហាញ ៣ ចំណុចសំខាន់ (Requirements Checklist)
* **ចំណុចទី 1 (Laravel REST API):** 
  * បង្ហាញ Controller & Routes ក្នុង `backend/routes/api.php`
  * បង្ហាញ API Endpoints: `/api/login` (Auth Sanctum), `/api/products`, `/api/orders`, `/api/reports`
* **ចំណុចទី 2 (MySQL Database Storage):**
  * បើក Database `mart_pos_db` លើ Laragon / HeidiSQL / phpMyAdmin
  * បង្ហាញតារាង `products`, `orders`, `order_items`
  * **បង្ហាញជាក់ស្តែងពេល Demo:** ពេលចុច Checkout លក់ទំនិញលើទូរស័ព្ទ ចំនួនស្តុកក្នុងតារាង `products` នឹងត្រូវកាត់ភ្លាមៗ (`stock_qty - qty`) ហើយវិក្កយបត្រថ្មីនឹងលោតចូលក្នុងតារាង `orders` ភ្លាមៗ 100%។
* **ចំណុចទី 3 (Design UI of App in Flutter):**
  * បង្ហាញ UI លើទូរស័ព្ទ (Modern UI, Dual-currency KHR/USD, Barcode Scan, Thermal Receipt, Hold/Resume Bill)។

---

### 2. បើសិនគ្រូសួរថា «ចុះបើដាច់ Internet ឬដាច់ភ្លើង Server Laravel តើ App គាំងអត់?»

> **ឆ្លើយយ៉ាងមានទំនុកចិត្តថា៖**  
> *«អត់គាំងទេលោកគ្រូ! ខ្ញុំបានរចនាប្រព័ន្ធនេះជាប្រភេទ **Hybrid Offline-First System**៖*  
> *1. **ផ្លូវមេ (Primary):** រត់ទៅកាន់ **Laravel REST API + MySQL** មុនគេបង្អស់។*  
> *2. **ផ្លូវបម្រុងទុក (Fallback):** មាន **Firebase Offline Cache** ជួយទប់ទល់។ ដូច្នេះទោះបីដាច់ Network ក៏ Cashier នៅតែអាច Scan ទំនិញ និងគិតលុយជូនភ្ញៀវលើទូរស័ព្ទបានធម្មតា មិនធ្វើឱ្យកកស្ទះដល់ការលក់ដូររបស់ម៉ាតឡើយ!»*

---

## 🛠️ របៀបបើកប្រព័ន្ធ Demo (How to Run)

### ជំហានទី ១: បើក MySQL & Backend API
1. បើក **Laragon** -> ចុច **Start All** (ដំណើរការ MySQL Port 3306)
2. បើក Terminal ចូល folder `backend` ហើយ Run Command:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8080
   ```

### ជំហានទី ២: បើក Flutter App
បើក Terminal ក្នុង Root Folder ហើយ Run:
```bash
flutter run
```

---

## 🔑 គណនីសម្រាប់សាកល្បង (Test Accounts)

* **Admin Manager:** `admin@martpos.com` / Password: `password123`
* **Cashier:** `cashier@martpos.com` / Password: `password123`
