# 📱 Expense Tracker (Flutter)

[![APK Downloads](https://img.shields.io/github/downloads/GyandeepEkansh/expense-tracker/total?color=2ea44f&label=APK%20Downloads&logo=android)](https://github.com/GyandeepEkansh/expense-tracker/releases)
[![Visitors](https://komarev.com/ghpvc/?username=GyandeepEkansh-expense-tracker&label=Total%20Visitors&color=0e75b6)](https://github.com/GyandeepEkansh/expense-tracker)
[![Latest Release](https://img.shields.io/github/v/release/GyandeepEkansh/expense-tracker?color=orange&label=Release)](https://github.com/GyandeepEkansh/expense-tracker/releases)
[![Live Demo](https://img.shields.io/badge/Demo-Live%20Web%20App-brightgreen?logo=googlechrome)](https://GyandeepEkansh.github.io/expense-tracker/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A fast, privacy-focused, offline-first mobile expense tracker designed for Indian Rupee (**₹**) with a calendar-centric workflow, visual spending breakdown, and biometric security.

---

## ✨ Features (v1.0 MVP)

* **📅 Calendar-Centric Home Screen**:
  * Month grid with Google Calendar style navigation and quick "Today" jump.
  * Dot indicators under dates with logged entries (clean, uncluttered cells).
  * Flexible date logging: past, today, and planned future dates.
* **📋 Day Detail Bottom Sheet**:
  * Tapping any date slides up that day's total in ₹ and transaction list.
  * Swipe-to-delete with Undo snackbar, tap to edit.
  * Quick "+ Add expense" button prefilled with the tapped date.
* **⚡ Quick Add Flow**:
  * Auto-focused numeric keypad on the Amount field with ₹ prefix.
  * Category chips with color icons + inline `+ New Category` creator.
  * Preselects last-used category for maximum logging speed.
* **📊 31-Day Cumulative Summary**:
  * Strict 31-day range limit with presets (*Today*, *7 Days*, *30 Days*, *Custom Range*).
  * Interactive donut chart showing category breakdown with percentage distribution and total ₹ spent.
* **🏷️ Category Management**:
  * Add, rename, or delete categories with customizable icons and colors.
  * **Deletion Safeguard**: Choose to move expenses to another category or delete all associated records permanently.
* **🔒 Security & App Lock**:
  * 4-digit PIN lock & biometric authentication (fingerprint/face).
  * Auto-lock timeout delay (Immediate, 1 min, 5 min).
* **🔔 Daily Reminders**:
  * Local notification reminder (default 9:00 PM: *"Did you log today's expenses?"*).
* **💾 Data & Backup**:
  * Export complete expense report to CSV (compatible with Excel & Google Sheets).
  * Full offline JSON database backup and restore.
  * Data wipe option.
* **🌓 Appearance**:
  * Light, Dark, and System Default themes.
  * First day of week customization (Sunday / Monday).

---

## 🚀 Live Demo & Download

* **Live Web App**: [https://GyandeepEkansh.github.io/expense-tracker/](https://GyandeepEkansh.github.io/expense-tracker/) *(runs directly in your browser or installable as PWA)*
* **Android APK**: Download the pre-built signed release APK from the [Releases](https://github.com/GyandeepEkansh/expense-tracker/releases) tab.

---

## 🛠️ Tech Stack & Architecture

* **Framework**: Flutter 3.47+ / Dart 3.13+
* **Storage**: Local persistent storage (offline-first)
* **Key Packages**:
  * `table_calendar` - Calendar view and month grid
  * `fl_chart` - Interactive pie/donut charts
  * `provider` - Reactive state management
  * `intl` - ₹ currency formatting and date localization
  * `shared_preferences` - Local persistent storage
  * `share_plus` - Report sharing

---

## 📦 Building from Source

```bash
# Clone the repository
git clone https://github.com/GyandeepEkansh/expense-tracker.git
cd expense-tracker

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run locally in Chrome / Android emulator
flutter run

# Build Android APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
```

---

## 📄 License
MIT License.
