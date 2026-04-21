# StudyMate – Complete Setup Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Flutter Setup in Android Studio](#1-flutter-setup-in-android-studio)
3. [Project Setup](#2-project-setup)
4. [Laravel Backend Setup](#3-laravel-backend-setup)
5. [Database Setup](#4-database-setup)
6. [Razorpay Payment Setup](#5-razorpay-payment-setup)
7. [API Integration](#6-api-integration)
8. [Build & Run](#7-build--run)
9. [Security Checklist](#8-security-checklist)
10. [Troubleshooting](#9-troubleshooting)

---

## Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Flutter | 3.19+ | https://flutter.dev/docs/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Java JDK | 17+ | https://adoptium.net |
| PHP | 8.1+ | https://php.net |
| Composer | 2.x | https://getcomposer.org |
| MySQL | 8.0+ | https://mysql.com |

---

## 1. Flutter Setup in Android Studio

### Step 1 – Install Flutter SDK
```bash
# macOS / Linux
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Windows – download zip from flutter.dev and add to PATH
```

### Step 2 – Install Flutter & Dart plugins in Android Studio
1. Open Android Studio → **Settings** → **Plugins**
2. Search for **Flutter** → Install (installs Dart automatically)
3. Restart Android Studio

### Step 3 – Set up Android Emulator
1. **Tools** → **Device Manager** → **Create Device**
2. Select **Pixel 6** (or any device with API 33+)
3. Download **API 34** system image
4. Click **Finish** and **Start** the emulator

### Step 4 – Verify installation
```bash
flutter doctor -v
# All items should show ✓ (Android toolchain, Android Studio, Connected device)
```

### Step 5 – Accept Android licenses
```bash
flutter doctor --android-licenses
# Press 'y' for each license
```

---

## 2. Project Setup

### Clone / copy the project
```bash
cd ~/projects
# If using git:
git clone https://github.com/yourorg/studymate.git
cd studymate

# Or copy the studymate folder here
```

### Install dependencies
```bash
flutter pub get
```

### Configure API base URL
Open `lib/core/constants/app_constants.dart` and set:
```dart
static const String baseUrl = 'https://YOUR-DOMAIN.com/api/v1';
```
For local dev (Android emulator uses `10.0.2.2` for localhost):
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

### Configure Razorpay Key
```dart
static const String razorpayKeyId = 'rzp_test_XXXXXXXXXXXXXXXX'; // test key
// Use rzp_live_XXX in production
```

### Add app icons (optional)
Replace files in `android/app/src/main/res/mipmap-*/` with your own icons,
or use the `flutter_launcher_icons` package.

---

## 3. Laravel Backend Setup

> You already have migrations and APIs. These steps assume a fresh server setup.

### Step 1 – Install PHP dependencies
```bash
cd /path/to/your-laravel-project
composer install
```

### Step 2 – Environment configuration
```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env`:
```env
APP_NAME="StudyMate API"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=studymate
DB_USERNAME=studymate_user
DB_PASSWORD=your_strong_password

# Razorpay
RAZORPAY_KEY_ID=rzp_live_XXXXXXXXXX
RAZORPAY_KEY_SECRET=your_secret_here

# JWT / Sanctum tokens
SANCTUM_STATELESS_DOMAINS=your-domain.com

# File storage (for PDFs)
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=ap-south-1
AWS_BUCKET=studymate-pdfs
# Or use local disk for development:
# FILESYSTEM_DISK=local
```

### Step 3 – Install Laravel Sanctum (if not already)
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

### Step 4 – Install Razorpay PHP SDK
```bash
composer require razorpay/razorpay
```

### Step 5 – CORS configuration
In `config/cors.php`:
```php
'allowed_origins' => ['*'], // restrict in production
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
'supports_credentials' => true,
```

### Step 6 – API routes (verify these exist in routes/api.php)
```php
// Auth
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/refresh', [AuthController::class, 'refresh']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/profile', [AuthController::class, 'profile']);

    // Data
    Route::get('/universities', [UniversityController::class, 'index']);
    Route::get('/universities/{university}/courses', [CourseController::class, 'index']);
    Route::get('/courses/{course}/semesters', [SemesterController::class, 'index']);
    Route::get('/semesters/{semester}', [SemesterController::class, 'show']);
    Route::get('/semesters/{semester}/old-papers', [OldPaperController::class, 'index']);
    Route::get('/papers/{paper}/view-url', [OldPaperController::class, 'viewUrl']);

    // Subscriptions
    Route::get('/subscriptions/check/{semester}', [SubscriptionController::class, 'check']);
    Route::post('/subscriptions/create-order', [SubscriptionController::class, 'createOrder']);
    Route::post('/subscriptions/verify-payment', [SubscriptionController::class, 'verifyPayment']);
    Route::get('/subscriptions/my', [SubscriptionController::class, 'mySubscriptions']);
});
```

### Step 7 – Example API response formats
All list endpoints should return:
```json
{ "data": [...], "message": "Success" }
```
Auth endpoints should return:
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "user": { "id": 1, "name": "...", "email": "...", "phone": "..." }
}
```
Subscription check:
```json
{ "is_subscribed": true }
```
Create order:
```json
{ "order_id": "order_XXXXXXXX", "amount": 7500, "currency": "INR" }
```

---

## 4. Database Setup

### Step 1 – Create database
```sql
CREATE DATABASE studymate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'studymate_user'@'localhost' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON studymate.* TO 'studymate_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 2 – Run migrations
```bash
php artisan migrate
```

### Step 3 – Seed initial data (optional)
```bash
php artisan db:seed
```

### Core tables expected by the app

| Table | Key columns |
|-------|-------------|
| users | id, name, email, phone, password |
| universities | id, name, logo, city |
| courses | id, university_id, name, short_name, description |
| semesters | id, course_id, name, semester_number, summary |
| old_papers | id, semester_id, title, subject, year, pdf_path, pages_count |
| subscriptions | id, user_id, semester_id, razorpay_order_id, razorpay_payment_id, status, start_date, end_date |

---

## 5. Razorpay Payment Setup

### Step 1 – Create Razorpay account
1. Go to https://razorpay.com → Sign up
2. Complete KYC for live payments
3. Dashboard → **Settings** → **API Keys** → Generate key pair

### Step 2 – Test mode first
Use test keys (`rzp_test_...`) during development.
Test card: `4111 1111 1111 1111`, any future expiry, any CVV.

### Step 3 – Webhook (important for reliability)
In Razorpay Dashboard → **Webhooks** → Add endpoint:
```
https://your-domain.com/api/v1/webhooks/razorpay
```
Events: `payment.captured`, `order.paid`

### Step 4 – Payment verification in Laravel
```php
// SubscriptionController::verifyPayment
$api = new \Razorpay\Api\Api(config('services.razorpay.key'), config('services.razorpay.secret'));

$attributes = [
    'razorpay_order_id'   => $request->razorpay_order_id,
    'razorpay_payment_id' => $request->razorpay_payment_id,
    'razorpay_signature'  => $request->razorpay_signature,
];

$api->utility->verifyPaymentSignature($attributes);
// If no exception thrown, payment is verified ✓

// Create subscription valid for 6 months
Subscription::create([
    'user_id'              => auth()->id(),
    'semester_id'          => $request->semester_id,
    'razorpay_order_id'    => $request->razorpay_order_id,
    'razorpay_payment_id'  => $request->razorpay_payment_id,
    'status'               => 'active',
    'start_date'           => now(),
    'end_date'             => now()->addMonths(6),
]);
```

---

## 6. API Integration

### PDF URL Security
Never expose direct S3/storage URLs. Generate signed temporary URLs:
```php
// OldPaperController::viewUrl
public function viewUrl(OldPaper $paper)
{
    // Check subscription
    $isSubscribed = auth()->user()->subscriptions()
        ->where('semester_id', $paper->semester_id)
        ->where('status', 'active')
        ->where('end_date', '>', now())
        ->exists();

    $url = $isSubscribed
        ? Storage::temporaryUrl($paper->pdf_path, now()->addMinutes(30))
        : Storage::temporaryUrl($paper->pdf_path, now()->addMinutes(5),
            ['ResponseContentDisposition' => 'inline']
          );

    return response()->json(['url' => $url, 'expires_in' => 1800]);
}
```

### Rate Limiting (add to RouteServiceProvider)
```php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('auth', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip()); // Prevent brute force
});
```

---

## 7. Build & Run

### Development (debug)
```bash
flutter run                        # default connected device
flutter run -d emulator-5554       # specific emulator
flutter run --dart-define=ENV=dev  # with env flag
```

### Release APK
```bash
# Generate keystore (only once)
keytool -genkey -v -keystore ~/studymate-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias studymate

# Create key.properties in android/
# key.properties:
# storePassword=your_store_pass
# keyPassword=your_key_pass
# keyAlias=studymate
# storeFile=/path/to/studymate-release.jks

# Build
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### Add signing to android/app/build.gradle
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 8. Security Checklist

### Flutter App
- [x] `FLAG_SECURE` blocks screenshots in PDF viewer via `MainActivity.kt`
- [x] Tokens stored in `flutter_secure_storage` (uses Android Keystore)
- [x] HTTPS enforced via `network_security_config.xml`
- [x] PDF viewer disables text selection
- [x] App locked to portrait orientation
- [x] No PDF download — only view via temporary signed URL
- [ ] Enable ProGuard/R8 in release build (in `build.gradle`)
- [ ] Remove debug logging (`LoggingInterceptor` only runs in debug)
- [ ] Use `flutter_native_splash` for branded splash screen

### Laravel Backend
- [ ] Razorpay signature verified server-side (never trust client)
- [ ] PDF URLs are signed temporary URLs (30 min expiry)
- [ ] Rate limiting on auth routes
- [ ] All endpoints behind `auth:sanctum` middleware
- [ ] `APP_DEBUG=false` in production
- [ ] Store `RAZORPAY_KEY_SECRET` only in `.env` (never in app)
- [ ] CORS restricted to your app domain in production

---

## 9. Troubleshooting

### `flutter pub get` fails
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Razorpay payment screen doesn't open
- Confirm `razorpayKeyId` is set correctly
- Check `READ_PHONE_STATE` permission in `AndroidManifest.xml`
- Minimum Android API level must be 19+

### PDF not loading
- Ensure the URL returned by the API is accessible (test in browser)
- Check network security config allows your domain
- For local dev, update `network_security_config.xml` to allow HTTP on `10.0.2.2`

### Screenshot still works in PDF viewer
- Ensure `MainActivity.kt` package name matches your app package
- Rebuild after changing native code: `flutter clean && flutter run`

### Token expired / 401 errors
- The `AuthInterceptor` auto-refreshes tokens
- If still failing, check the `/auth/refresh` endpoint is implemented in Laravel
- Clear app data to force re-login during development

### Build fails with Kotlin version error
In `android/build.gradle`, update:
```groovy
ext.kotlin_version = '1.9.22'
```
