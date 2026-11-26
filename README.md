# 🏪 ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart POS & Inventory System)

<div align="center">

### សាកលវិទ្យាល័យ បៀលប្រាយ (Build Bright University - BBU)
**សាខាខេត្តបាត់ដំបង (Battambang Campus)**  
**មហាវិទ្យាល័យ វិទ្យាសាស្ត្រ និងបច្ចេកវិទ្យាព័ត៌មាន (Faculty of Information Technology)**  
**ឆ្នាំទី ៤ ឆមាសទី ២ (Year 4, Semester 2)**

---

### 👥 សមាជិកក្រុមស្រាវជ្រាវ និងអភិវឌ្ឍន៍ (Team Members):
1. **គុយ ដាលី** (Kuy Daly)
2. **គក់ ស្រីផ្កាយ** (Kok Sreyphkay)
3. **នី បញ្ញា** (Ny Panha)

</div>

---

## 📌 សេចក្តីផ្តើមអំពីគម្រោង (Project Overview)
**ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart POS & Inventory System)** គឺជាប្រព័ន្ធគ្រប់គ្រងការលក់ និងស្តុកទំនិញពេញលេញ (Fullstack Application) ដែលត្រូវបានអភិវឌ្ឍឡើងស្របតាមតម្រូវការសិក្សាជាក់ស្តែង ដោយរួមបញ្ចូលនូវបច្ចេកវិទ្យាសំខាន់ៗចំនួន ៣៖
1. **Laravel REST API:** ដើរតួជា Backend ស្នូលសម្រាប់គ្រប់គ្រង Business Logic, Authentication, និង API Endpoints។
2. **MySQL Database:** ដើរតួជាឃ្លាំងផ្ទុកទិន្នន័យចម្បង (Primary Storage) សម្រាប់ Products, Categories, Users, Orders និង Sales។
3. **Flutter UI:** ដើរតួជា Frontend Mobile & Multi-platform Application ដែលមាន UI/UX ទំនើប ងាយស្រួលប្រើប្រាស់។

លើសពីនេះ ប្រព័ន្ធត្រូវបានបំពាក់នូវស្ថាបត្យកម្ម **Hybrid Offline-First** ដោយមាន **Firebase Cloud Firestore** ជាប្រព័ន្ធបម្រុងទុក (Fallback) ពេលដាច់ Network។

---

## 🛠️ បច្ចេកវិទ្យាប្រើប្រាស់ (Tech Stack)

| ផ្នែក (Component) | បច្ចេកវិទ្យា (Technology) | មុខងារលម្អិត |
|---|---|---|
| **Frontend UI** | **Flutter (Dart 3.x)** | UI/UX សម្រាប់ POS Mobile, Tablet និង Desktop |
| **State Management** | **Flutter Riverpod** | គ្រប់គ្រង State ទូទាំង App យ៉ាងមានប្រសិទ្ធភាព |
| **Backend REST API** | **Laravel (PHP 8.3)** | ផ្តល់សេវា API JSON, Token Auth (Sanctum) និង Business Logic |
| **Primary Database** | **MySQL (Laragon)** | រក្សាទុកទិន្នន័យស្នូល (`mart_pos_db`) ជាមួយ Migrations & Seeders |
| **Offline Resilience** | **Firebase (Firestore & Auth)** | ឃ្លាំងទិន្នន័យបម្រុងទុក (Offline Cache / Fallback) ពេលដាច់ Network |
| **Payment Engine** | **Dual-Currency & KHQR** | គណនារូបិយប័ណ្ណពីរ (USD / KHR អត្រា 4,100៛) និង Bakong KHQR |
| **Barcode Engine** | **Mobile Scanner** | ស្កេនបាកូដទំនិញរហ័សតាម Camera និង Barcode Reader |

---

## 📐 ស្ថាបត្យកម្មប្រព័ន្ធ (System Architecture)

```
[ Flutter Mobile App (UI) ]
         │
         ├── (1) Primary API (JSON / HTTP) ──> [ Laravel REST API (:8080) ]
         │                                                │
         │                                                ▼
         │                                     [ MySQL Database (:3306) ]
         │                                           (mart_pos_db)
         │
         └── (2) Offline Cache (Fallback) ───> [ Firebase Cloud Firestore ]
```

---

## ✅ មុខងារចម្បងៗរបស់ប្រព័ន្ធ (Key Features)

### 1. 🛒 ផ្ទាំងគិតលុយលក់ដូរ (POS Cashier Terminal)
* បង្ហាញមុខទំនិញតាមប្រភេទ (Category Chips): ភេសជ្ជៈ, មី និងអាហារស្រាល, នំបុ័ង និងនំចំណី, សម្ភារៈប្រើប្រាស់។
* ស្វែងរកទំនិញតាមឈ្មោះ ឬតាមរយៈការស្កេនបាកូដ (Barcode Scanner)។
* បន្ថែមទំនិញចូលកន្ត្រក, កែប្រែចំនួន (+/-), និងបញ្ចុះតម្លៃ (Discount)។
* មុខងារ **Hold Bill / Resume Bill** (ផ្អាកវិក្កយបត្របណ្តោះអាសន្ន និងបន្តការលក់ឡើងវិញ)។

### 2. 💵 ការទូទាត់ប្រាក់ និងវិក្កយបត្រ (Checkout & Thermal Receipt)
* គណនាប្រាក់សរុបស្វ័យប្រវត្តិតាមរូបិយប័ណ្ណពីរ (USD និង KHR)។
* ជម្រើសទូទាត់ប្រាក់៖ Cash (USD), Cash (KHR), និង Bakong KHQR។
* ប៊ូតុងគិតលុយរហ័សតាមក្រដាសប្រាក់ (\$1, \$5, \$10, \$20, \$50 ឬ 5,000៛, 10,000៛, 50,000៛)។
* គណនាប្រាក់អាប់ជូនអតិថិជនបានត្រឹមត្រូវ ១០០%។
* បង្ហាញវិក្កយបត្រ (Receipt) បែប Thermal Printer មាន QR Code សម្រាប់ផ្ទៀងផ្ទាត់។

### 3. 📦 គ្រប់គ្រងស្តុកទំនិញ (Inventory Management)
* បង្ហាញបញ្ជីទំនិញទាំងអស់ក្នុងម៉ាត (ឈ្មោះ, Barcode, តម្លៃដើម, តម្លៃលក់, ចំនួនស្តុក)។
* បន្ថែមទំនិញថ្មី, កែប្រែព័ត៌មានទំនិញ, និងលុបទំនិញ។
* ប្រព័ន្ធជូនដំណឹងពេលទំនិញ **ជិតអស់ពីស្តុក (Low Stock Alert <= 5)**។
* **កាត់ស្តុកទំនិញស្វ័យប្រវត្តិក្នុង MySQL** ភ្លាមៗពេលមានការលក់ចេញ (Auto Stock Deduction)។

### 4. 📊 របាយការណ៍លក់ (Sales Analytics & Reports)
* សង្ខេបចំណូលសរុបប្រចាំថ្ងៃជា USD (\$) និង KHR (៛)។
* ចំនួនវិក្កយបត្រដែលបានលក់ចេញសរុប។
* បញ្ជីប្រវត្តិវិក្កយបត្រលក់លម្អិត និងអាចបើកមើលឡើងវិញបានគ្រប់ពេល។

### 5. 🔐 ប្រព័ន្ធសុវត្ថិភាព និងកំណត់សិទ្ធិ (Role-based Access)
* **ADMIN_MANAGER / ADMIN:** គ្រប់គ្រងទំនិញ, ប្រភេទ, មើលរបាយការណ៍ និងគ្រប់គ្រងគណនី។
* **CASHIER:** ប្រើប្រាស់ផ្ទាំង POS លក់ដូរទំនិញ និងចេញវិក្កយបត្រ។

---

## 🚀 របៀប Run ដំណើរការគម្រោង (How to Run)

### ជំហានទី ១៖ បើក MySQL Database
1. បើកកម្មវិធី **Laragon** (ឬ XAMPP)
2. ចុច **Start All** ដើម្បីដំណើរការ MySQL Server (Port `3306`)

### ជំហានទី ២៖ ដំណើរការ Laravel Backend API
បើក Terminal ចូលទៅកាន់ folder `backend`៖
```bash
cd backend
composer install
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8080
```
*(Backend REST API នឹងដំណើរការនៅ `http://localhost:8080` ឬតាម Wi-Fi IP ក្នុងបណ្តាញ Local)*

### ជំហានទី ៣៖ ដំឡើង FVM & ដំណើរការ Flutter Frontend App
គម្រោងនេះប្រើ **FVM (Flutter Version Management)** ជាមួយ Flutter SDK version **`3.47.7`** (ដើម្បីឲ្យ Team ទាំងអស់ប្រើ version ដូចគ្នាពេល `clone` ឬ `pull`)។

បើក Terminal ថ្មីមួយទៀតក្នុង Root Folder នៃគម្រោង៖
```bash
# 1. ដំឡើង FVM (ធ្វើតែម្តងដំបូងបើមិនទាន់មាន fvm)
dart pub global activate fvm

# 2. ទាញយក និងប្រើ Flutter SDK 3.47.7 តាម .fvm/fvm_config.json
fvm install 3.47.7
fvm use 3.47.7

# 3. ទាញ packages និង run (ធ្វើរាល់ពេលក្រោយ git clone / git pull)
fvm flutter pub get
fvm flutter run
```
*(បើគ្មាន `fvm` ក្នុង PATH លើ Windows អាចប្រើ `.\.fvm\flutter_sdk\bin\flutter.bat pub get` និង `.\.fvm\flutter_sdk\bin\flutter.bat run` ជំនួសបាន។ អាច Run លើទូរស័ព្ទ Android ពិត, Chrome Web, ឬ Desktop)*

---

## 🔑 គណនីសម្រាប់សាកល្បង Demo (Default Credentials)

| តួនាទី (Role) | អ៊ីមែល (Email) | ពាក្យសម្ងាត់ (Password) |
|---|---|---|
| **Admin Manager** | `admin@martpos.com` | `password123` |
| **Cashier (អ្នកគិតលុយ)** | `cashier@martpos.com` | `password123` |

---

## 🛠️ ការកែលម្អ និងជួសជុលថ្មីៗ (Recent Fixes & Updates)

### 1. 🔐 Biometric Unlock (`local_auth` + `flutter_secure_storage`)
* **Cold-Start Biometric Lock Gate (`BiometricLockScreen`)**: ការពារការបើក app ឡើងវិញដោយស្កេនម្រាមដៃ ឬផ្ទៃមុខ (រារាំង Android Back button តាម `PopScope` និង block deep-link ទៅ `/admin` ឬ `/pos` រហូតដល់ផ្ទៀងផ្ទាត់រួច)។
* **One-Time Enable Offer**: បង្ហាញ dialog `"Enable biometric unlock?"` ម្តងគត់លើ `MainShell` ក្រោយ login ដោយ password ជោគជ័យ។
* **Login Screen Quick Scan**: បន្ថែមប៊ូតុង `"Log in with Fingerprint / Face"` នៅក្រោម `SIGN IN` ពេលមាន session និងឧបករណ៍ support biometrics (មិនរក្សាទុក password ឡើយ)។
* **Settings Toggle**: អាចបិទ/បើក Biometric Unlock ក្នុង **Shop Settings → Appearance** (Admin) និង **My Shift → Security** (Cashier)។

### 2. 🏷️ Supplier Product Picker Category Filter
* បន្ថែម Category filter chips (`ទាំងអស់ (All)` និងគ្រប់ Category) ក្នុងផ្ទាំង **ជ្រើសរើសទំនិញផ្គត់ផ្គង់** (`supplier_form_dialog.dart`) ព្រមទាំងអាចស្វែងរកតាមឈ្មោះ Category និងបង្ហាញ `Code • Category`។

### 3. 📱 Mobile Responsive & Overflow Fixes
* **Staff & Shifts (`users_screen.dart`)**: កែ `Row` ឈ្មោះបុគ្គលិក + Role badge ទៅជា `Wrap`, សម្រួល Switch layout លើ mobile, និងការពារការដាច់អក្សរលើ `TabBar`។
* **Audit Log (`audit_logs_screen.dart`)**: កែ **Date Filter** row ទៅជា `Column` + `Wrap` ដើម្បីកុំឲ្យ overflow លើអេក្រង់ទូរស័ព្ទ។

### 4. 🔌 Run លើទូរស័ព្ទ Android ពិតតាម USB vs Emulator / Chrome
* **Chrome / Windows / Android Emulator**: ប្រើ `fvm flutter run` ធម្មតា (Emulator ស្គាល់ `10.0.2.2:8080` ស្រាប់)។
* **ទូរស័ព្ទ Android ពិត (តាម USB)**: ត្រូវដាក់ `adb reverse` និង `--dart-define=API_BASE_URL=...` ដើម្បីកុំឲ្យជាប់ error `No route to host` (`10.0.2.2`)៖
```bash
adb reverse tcp:8080 tcp:8080
fvm flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api
```
*(បើគ្មាន `fvm` ក្នុង PATH លើ Windows អាចប្រើ `.\.fvm\flutter_sdk\bin\flutter.bat` ជំនួស `fvm flutter`)*
