# 📱 Faustina - Flutter Finance Tracker App

A comprehensive Flutter application for tracking daily sales and expenses with advanced reporting and analytics capabilities.

---

## 📁 Folder Structure
```bash
finance_tracker/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/
│   ├── main.dart            # App entry point
│   ├── models/
│   │   └── models.dart      # Data models
│   ├── services/
│   │   ├── database_helper.dart
│   │   ├── pdf_service.dart
│   │   ├── csv_service.dart
│   │   ├── cloud_sync_service.dart
│   │   └── receipt_service.dart
│   └── pages/
│       ├── home_page.dart
│       ├── sales_page.dart
│       ├── expenses_page.dart
│       ├── report_page.dart
│       ├── charts_page.dart
│       ├── import_export_page.dart
│       ├── cloud_sync_page.dart
│       └── business_profile_page.dart
├── assets/                  # Static assets
├── pubspec.yaml             # Dependencies configuration
└── README.md                # Project overview

```

## 📱 Features

### Core Functionality
- **Sales Tracking**: Record and manage sales transactions
- **Expense Management**: Track business expenses with categories
- **Receipt Capture**: Attach photos to sales with camera/gallery integration
- **Financial Reports**: Generate professional PDF reports
- **Data Analytics**: Visual charts and graphs for financial analysis

### Advanced Features
- **Cloud Sync**: Automatic backup to Google Drive (see [CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md))
- **Import/Export**: CSV data import/export functionality
- **Business Profile**: Manage business owner information
- **Responsive Design**: Works on all screen sizes (mobile, tablet, desktop)

### Reporting & Analytics
- **PDF Reports**: Professional financial reports with business header
- **Visual Charts**: Profit & Loss pie charts, Sales vs Expenses comparison, Category-wise breakdowns, Monthly trend analysis
- **Date Range Filtering**: Customizable reporting periods

---

## 🛠️ Technical Stack

### Frontend
- Flutter - Cross-platform framework
- Dart - Programming language

### Backend & Storage
- SQLite - Local database
- Google Drive API - Cloud synchronization
- Shared Preferences - Local settings storage

### Key Dependencies
```yaml
# UI & Charts
syncfusion_flutter_datepicker: ^23.1.43
fl_chart: ^0.66.2

# PDF & Printing
pdf: ^3.10.4
printing: ^5.10.2

# File Management
file_picker: ^6.1.1
csv: ^5.0.2
image_picker: ^1.0.4
image_cropper: ^4.0.1

# Cloud Services
google_sign_in: ^6.1.5
http: ^1.1.0

# Utilities
intl: ^0.18.1
path_provider: ^2.1.1
shared_preferences: ^2.2.2
permission_handler: ^11.0.1
share_plus: ^7.0.2
```

---

## ☁️ Cloud Sync Configuration

To enable Google Drive cloud sync functionality:

1. **Follow the complete setup guide**: [CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md)
2. **Quick configuration reference**: [CONFIGURATION_TEMPLATE.md](CONFIGURATION_TEMPLATE.md)
3. **Quick commands**: [QUICK_COMMANDS.md](QUICK_COMMANDS.md)

### Quick Start:

1. Get your SHA-1 fingerprint:
   ```powershell
   cd android
   .\gradlew signingReport
   ```

2. Configure Google Cloud Console (see CLOUD_SYNC_SETUP.md)

3. Update `android/app/build.gradle.kts` with your Client ID

4. Test the app:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

**Note**: AndroidManifest.xml is already configured ✓

---

## 🚀 Getting Started

### Installation

```powershell
flutter pub get
