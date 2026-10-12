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
**ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart POS & Inventory System)** គឺជាកម្មវិធី Mobile & Multi-platform Application បង្កើតឡើងដោយប្រើប្រាស់ **Flutter (Dart)** រួមជាមួយ **Google Firebase (Cloud Firestore & Authentication)** ដែលត្រូវបានរចនាឡើងយ៉ាងពិសេសសម្រាប់ជួយសម្រួលដល់ដំណើរការលក់ដូរ និងគ្រប់គ្រងស្តុកទំនិញនៅតាមបណ្តាម៉ាតខ្នាតតូច និងមធ្យម (Mini-markets / Retail Shops)។

ប្រព័ន្ធនេះត្រូវបានរចនាឡើងយ៉ាងយកចិត្តទុកដាក់ខ្ពស់ជាពិសេសជាមួយ UI/UX ទំនើប ងាយស្រួលប្រើប្រាស់ និងសរសេរកូដឡើងវិញទាំងស្រុងជាភាសា **Dart (Flutter)** ស្របតាមតម្រូវការសិក្សាជាក់ស្តែង។

---

## 🛠️ បច្ចេកវិទ្យាប្រើប្រាស់ (Tech Stack)
* **Frontend Application:** Flutter 3.47+ (Dart 3.13+)
* **State Management:** Provider Architecture
* **Database & Cloud:** Google Firebase (Cloud Firestore & Authentication)
* **Payment & Currency:** Dual-Currency Engine (USD \$ និង KHR ៛ អត្រាប្តូរប្រាក់ 4,100៛) & Bakong KHQR QR Code
* **Barcode Engine:** Barcode / QR Code Quick-Scan & Search

---

## ✅ មុខងារចម្បងៗរបស់ប្រព័ន្ធ (Key Features)

### 1. 🛒 ផ្ទាំងគិតលុយលក់ដូរ (POS Cashier Terminal)
* បង្ហាញមុខទំនិញតាមប្រភេទ (Category Chips): ភេសជ្ជៈ, មី និងអាហារស្រាល, នំបុ័ង និងនំចំណី, សម្ភារៈប្រើប្រាស់។
* ស្វែងរកទំនិញតាមឈ្មោះ ឬតាមរយៈការស្កេនបាកូដ (Barcode Input/Scanner)។
* បន្ថែមទំនិញចូលកន្ត្រក, កែប្រែចំនួន (+/-), បញ្ចុះតម្លៃ (Discount)។
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
* កាត់ស្តុកទំនិញស្វ័យប្រវត្តិភ្លាមៗពេលមានការលក់ចេញ (Auto Stock Deduction)។

### 4. 📊 របាយការណ៍លក់ (Sales Analytics & Reports)
* សង្ខេបចំណូលសរុបប្រចាំថ្ងៃជា USD (\$) និង KHR (៛)។
* ចំនួនវិក្កយបត្រដែលបានលក់ចេញសរុប។
* បញ្ជីប្រវត្តិវិក្កយបត្រលក់លម្អិត និងអាចបើកមើលឡើងវិញបានគ្រប់ពេល។

### 5. 👥 ព័ត៌មានក្រុមការងារ (Team & Switch Demo User)
* បង្ហាញឈ្មោះសមាជិកក្រុមនិស្សិត BBU និងតួនាទី។
* ប៊ូតុងប្តូរគណនីប្រើប្រាស់ភ្លាមៗសម្រាប់ Demo ជូនគ្រូ (Admin vs Cashier)។

---

## 🚀 របៀប Run ដំណើរការកម្មវិធី (How to Run)

### Firebase role setup and existing data migration

The app uses `ADMIN_MANAGER`, `ADMIN`, and `CASHIER` profiles. Shop-owned documents carry a `shopId`; existing unscoped records are assigned to `default-shop` by the migration script.

1. Install the Cloud Functions dependencies with `cd functions && npm install`.
2. Create the intended first manager in Firebase Authentication. Copy `functions/.env.example` to `functions/.env.mart-pos-app` and set `BOOTSTRAP_MANAGER_UID` to that Auth UID, then deploy Functions. The login screen's **Initialize first platform manager** action calls the bootstrap function; it only works for that allowlisted UID while no manager profile exists. Existing shop users are allowed.
3. Run the migration in dry-run mode from the project root: `node scripts/migrate-default-shop.js`. Review the planned paths and counts before applying it.
4. Back up Firestore. Then apply with `ALLOW_LIVE_MIGRATION=1 node scripts/migrate-default-shop.js --apply`. The script checks document counts and confirms a second plan is empty. Do not deploy the shop-scoped rules until this verification succeeds.
5. Deploy Firestore rules after migration: `firebase deploy --only firestore:rules`.

The migration is idempotent and does not run during deploy. The script requires explicit apply flags before writing. Cloud Functions use the Admin SDK for shop provisioning, user role changes, subscriptions, and platform reports.

#### Firebase Emulator checks

Start the Auth, Firestore, and Functions emulators with `firebase emulators:start --only auth,firestore,functions`. Use a disposable emulator project when testing role access and callable workflows.

Run the automated Firestore authorization and migration repeatability checks with `firebase emulators:exec --project demo-mart-pos --only firestore "cd functions && npm run test:rules"`.

### ជំហានទី ១៖ ចូលទៅកាន់ Folder គម្រោង
```bash
cd /home/nha/Desktop/mart_pos
```

### ជំហានទី ២៖ ទាញយក Packages
```bash
flutter pub get
```

### ជំហានទី ៣៖ Run កម្មវិធីលើ Chrome Web (ងាយស្រួល និងលឿនបំផុតសម្រាប់ Demo)
```bash
flutter run -d chrome
```

*(ឬបើចង់ run លើ Linux Desktop)*
```bash
flutter run -d linux
```

*(ឬបើចង់ run លើទូរស័ព្ទ Android)*
```bash
flutter run -d <android-device-id>
```
