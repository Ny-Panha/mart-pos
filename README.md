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

### ជំហានទី ១៖ ដំឡើង Tools និង Clone Project (Windows)

ដំឡើង Git, Android Studio (Android SDK និង JDK 25; ឧទាហរណ៍ Android Studio JBR 25.0.3) និង Flutter/Dart ជាមុន។ អាចដំឡើង Flutter តាម [Flutter on Windows](https://docs.flutter.dev/get-started/install/windows) ហើយបន្ថែម `flutter\bin` ទៅក្នុង `PATH`។

Project នេះ pin **Flutter 3.47.7** និង **Dart 3.13.5** តាម FVM។ មិនចាំបាច់ប្ដូរ Global Flutter SDK ទេ។ បើក Windows PowerShell ហើយដំឡើង FVM ម្តង៖

```powershell
dart pub global activate fvm 4.3.2
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
fvm --version
```

បើចង់ឱ្យ `fvm` ដំណើរការនៅ Terminal ថ្មីផង សូមបន្ថែម `%LOCALAPPDATA%\Pub\Cache\bin` ទៅ User PATH របស់ Windows។

បើក PowerShell ក្នុង folder ដែលចង់រក្សាទុក Project (កុំ Clone ក្នុង `C:\Windows\System32`) រួច Run៖

```powershell
git clone -b ui/full-frontend-rebuild https://github.com/Ny-Panha/mart-pos.git
cd mart-pos
fvm install
fvm use 3.47.7 --skip-pub-get
fvm flutter --version
fvm flutter pub get --enforce-lockfile
```

លទ្ធផល SDK ដែលត្រូវទទួលបាន៖ **Flutter 3.47.7 stable / Dart 3.13.5**។ FVM នឹងប្រើ SDK ដែលបានកំណត់ក្នុង `.fvmrc` ហើយ `pubspec.lock` រក្សា package versions ដូចគ្នាសម្រាប់ក្រុម។ កុំប្រើ `flutter upgrade` ឬ `flutter pub upgrade` ដោយមិនមានការឯកភាពពីក្រុម។

### ជំហានទី ២៖ បើក MySQL Database

1. បើកកម្មវិធី **Laragon** (ឬ XAMPP)
2. ចុច **Start All** ដើម្បីដំណើរការ MySQL Server (Port `3306`)

### ជំហានទី ៣៖ ដំណើរការ Laravel Backend API

បើក Terminal ចេញពី root folder `mart-pos` ចូលទៅកាន់ folder `backend`៖

```bash
cd backend
composer install
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8080
```

*(Backend REST API នឹងដំណើរការនៅ `http://localhost:8080` ឬតាម Wi-Fi IP ក្នុងបណ្តាញ Local)*

### ជំហានទី ៤៖ ដំណើរការ Flutter Frontend App

ទុក Backend Terminal ឱ្យដំណើរការ ហើយបើក PowerShell មួយទៀតនៅ root folder `mart-pos`។ បើក Android emulator ឬភ្ជាប់ Android device រួច Run៖

```powershell
fvm flutter devices
fvm flutter run
```

ក្នុង VS Code បើក root folder នៃគម្រោង ដើម្បីប្រើ SDK នៅ `.fvm/flutter_sdk`។ ប្រើ `fvm flutter` ជំនួស `flutter` ក្នុង Terminal ដើម្បីធានាថាប្រើ SDK ដែល Project បាន pin។

### ជំហានទី ៥៖ ពិនិត្យ Project (Optional)

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
git diff --exit-code -- pubspec.lock
```

APK ដែល build បានស្ថិតនៅ `build/app/outputs/flutter-apk/app-debug.apk`។ SDK cache `.fvm/`, `.dart_tool/` និង build outputs មិនត្រូវបាន commit ទេ។ Backend Laravel/MySQL ត្រូវដំណើរការដាច់ដោយឡែកតាមជំហានខាងលើ។

### 📝 ចំណាំសម្រាប់សមាជិកក្រុម (After Cloning)

បន្ទាប់ពី Clone branch ដូចគ្នា និង Setup តាមជំហានខាងលើ សមាជិកក្រុមអាច Run MART POS ដោយប្រើ source code និង SDK versions ដូចគ្នា។ មិនចាំបាច់ Copy Flutter SDK ឬ Project folder ពីកុំព្យូទ័រអ្នកដទៃទេ។

| ផ្នែក | លទ្ធផលដែលរំពឹងទុក |
|---|---|
| UI Design និង Features | ដូចគ្នាសម្រាប់ Git commit ដូចគ្នា; អាចមានភាពខុសគ្នាតាមទំហំអេក្រង់ និង platform |
| Flutter SDK | 3.47.7 stable |
| Dart SDK | 3.13.5 |
| Package Versions | ដូចគ្នាតាម `pubspec.lock` |
| MySQL Database | ត្រូវ Setup និង migrate/seed; ទិន្នន័យ local មិនត្រូវបាន Clone តាម Git ទេ |
| Laravel API | ត្រូវកំណត់ environment និង API URL ឱ្យត្រូវនឹងម៉ាស៊ីន/ឧបករណ៍ដែលប្រើ |
| Firebase | ត្រូវមាន configuration និងសិទ្ធិប្រើប្រាស់ត្រឹមត្រូវ |

**រាល់ពេលចង់បើក App ក្រោយ Setup រួច៖** បើក MySQL និង Laravel Backend សម្រាប់មុខងារដែលប្រើ API រួចបើក Terminal នៅ root folder `mart-pos` និង Run៖

```powershell
fvm flutter run
```

បើទទួលបានការកែប្រែថ្មីពីក្រុម សូមទាញ Git updates ហើយរត់ `fvm install` និង `fvm flutter pub get --enforce-lockfile` មុន Run។ កុំ commit ឯកសារ `.env`, credentials ឬ machine-specific SDK paths។ ការដំណើរការជាក់ស្តែងអាស្រ័យលើការដំឡើង tools, device, backend និង configuration នៅលើកុំព្យូទ័ររបស់សមាជិកនីមួយៗ។

---

## 🔑 គណនីសម្រាប់សាកល្បង Demo (Default Credentials)

| តួនាទី (Role) | អ៊ីមែល (Email) | ពាក្យសម្ងាត់ (Password) |
|---|---|---|
| **Admin Manager** | `admin@martpos.com` | `password123` |
| **Cashier (អ្នកគិតលុយ)** | `cashier@martpos.com` | `password123` |
