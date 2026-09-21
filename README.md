# 🦷 DentaFlow — Dental Clinic Management SaaS

[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS%20%7C%20macOS-blue)](#)
[![Tests](https://img.shields.io/badge/Tests-203%2B%20Passing-brightgreen)](#)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](#)

> **Modern, role-aware, multi-tenant dental clinic management platform.**
> Bringing appointments, patient records, interactive odontogram charting, treatment plans, procedure catalogs, billing, and staff management into a single, cohesive workspace.

---

## 🌟 Key Features

### 🦷 Interactive Dental Chart (Odontogram)
* **Visual Adult Notation**: Comprehensive tooth surface conditions (sound, decay, restoration, extraction, crown, endodontic, implant).
* **Clinical History Tracking**: Stage-by-stage tooth condition tracking across diagnostic visits.
* **Role Gate**: Protected clinical write access reserved for dentists and clinic owners.

### 📋 Procedure Catalogue & Treatment Plans
* **Specialty Standard Templates**: 16 standardized procedures pre-loaded across 6 dental specialties:
  * 🩺 *Preventive* (Consultation, Scaling & Polishing, Fluoride)
  * 🩹 *Restorative* (Composite Fillings, Temporary Fillings)
  * 🔬 *Endodontics* (Root Canal Treatments)
  * 🔪 *Surgery* (Simple & Surgical Extractions, Wisdom Tooth)
  * 🦷 *Periodontics & Prosthodontics* (Deep Scaling, Crowns, Dentures)
  * ✨ *Cosmetic* (Teeth Whitening)
* **1-Tap Starter Pack**: Quick catalog bootstrap with localized specialty pricing and descriptions.
* **Dynamic Search & Filtering**: Live search by name or category, active status filter, and duration chips.

### 📅 Appointment Agenda & Calendar
* **Day & Week Views**: Dense, color-coded calendar cards with distinct statuses:
  * 🔵 *Scheduled* &nbsp;|&nbsp; 🟢 *Confirmed* &nbsp;|&nbsp; 🟠 *In Progress* &nbsp;|&nbsp; 🔘 *Completed* &nbsp;|&nbsp; 🔴 *No-Show* &nbsp;|&nbsp; ⚫ *Cancelled*
* **1-Tap Quick Actions**: Instant status updates, quick navigation to patient profiles, and deep linking into active clinical sessions.
* **Clinical Preparation Notes**: Highlighted alerts for special patient preparation requirements.
* **Doctor Schedule Conflict Guards**: Overlap detection and owner-authorized schedule overrides.

### 👥 Patient Profile & Medical History
* **Full Patient Record**: Contact info, file numbers, date of birth with calculated age, and pediatric minor badges.
* **Medical Alert Banners**: Color-coded alerts for drug allergies, systemic medical conditions, and active medications.
* **Radiographs & Diagnostic Files**: Resumable, chunked file upload to private Supabase storage.

### 💳 Billing & Financial Ledger
* **Itemized Invoicing**: Multi-currency procedure billing, exact discounts, and tax computation.
* **Payment Processing**: Multi-method payments (Cash, Card, Bank Transfer) with partial payment and patient credit support.
* **Multilingual PDF Invoices**: Generates clean, printable invoices in English, Arabic (with native RTL shaping), and Russian.

### 🔐 Multi-Tenant Role-Based Access Control (RBAC)
* **Four Dedicated Roles**:
  * 👑 **Clinic Owner**: Full operational, administrative, financial, and audit trail control.
  * 🩺 **Dentist**: Patient records, dental charting, treatment planning, and clinical session completion.
  * 🧤 **Assistant**: Operational agenda, preparation notes, and clinical support.
  * 💼 **Receptionist**: Appointments, check-ins, patient registration, and billing.
* **Clinic Gate**: Seamless multi-clinic selection and onboarding for staff members.

### 🌐 Trilingual Localization & RTL Support
* **Languages Supported**:
  * 🇬🇧 **English** (`en`)
  * 🇸🇦 **Arabic** (`ar`) — with full native Right-to-Left (RTL) layout support.
  * 🇷🇺 **Russian** (`ru`)
* **Live Theme Switching**: Light and Dark Material 3 color palettes with persistent preferences.

---

## 🏗️ Architecture & Technology Stack

* **Framework**: Flutter `3.44.8` / Dart `3.12.2` (Null-safe)
* **State Management**: BLoC / Cubit (`flutter_bloc: 9.1.1`)
* **Routing**: GoRouter (`go_router: 17.5.0`) with authenticated guards and auth-callback interception.
* **Dependency Injection**: GetIt (`get_it: 9.2.1`) + Injectable (`injectable: 3.0.0`)
* **Backend & Auth**: Supabase (`supabase_flutter: 2.17.2`) with secure storage and session coordination.
* **Network**: Dio (`dio: 5.11.1`) with custom preflight & CORS interceptors.
* **Data Models**: Freezed (`freezed_annotation: 3.1.0`) & JsonSerializable (`json_annotation: 4.12.0`).

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK `^3.44.0` (Dart `^3.12.0`)
* Git
* Android Studio / Xcode (for mobile builds)
* Google Chrome (for web testing)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/nourbagh0-star/dental_clini_management_saas.git
   cd dental_clini_management_saas
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code & localizations**:
   ```bash
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run on Chrome (Web)**:
   ```bash
   flutter run -d chrome
   ```

5. **Run on Android device/emulator**:
   ```bash
   flutter run -d android
   ```

---

## 📦 Building Releases

### Android APK (Release)
To compile a release Android APK:
```bash
flutter build apk --release
```
The output APK is generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

To install directly to a connected Android phone or emulator:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Web Production Bundle
```bash
flutter build web --release
```

---

## 🧪 Testing & Code Quality

Run the complete automated test suite (203+ tests):
```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze

# Verify multilingual parity across AR, EN, and RU
flutter test test/app/localization_parity_test.dart
```

---

## 📄 License & Disclaimer

* **Disclaimer**: This application is currently configured for development and staging environments using fictional data only. It is not yet certified for live patient clinical records.
* **Copyright**: © 2026 DentaFlow. All rights reserved.
