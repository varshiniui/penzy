# Penzy — Stationery Shopping App

A Flutter e-commerce application for browsing and purchasing stationery products. The app features a warm, cozy aesthetic with real-time product data powered by Firebase, GPS-based delivery detection, a drag-and-drop cart system, and a complete authentication flow.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Screens and Components](#screens-and-components)
- [Firebase Integration](#firebase-integration)
- [Location Services](#location-services)
- [Design System](#design-system)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
- [Default Credentials](#default-credentials)
- [Assets](#assets)

---

## Project Structure

```
stationery_app/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── assets/
│   └── images/
├── lib/
│   ├── firebase_options.dart
│   └── main.dart
├── test/
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── firebase.json
├── pubspec.lock
├── pubspec.yaml
└── stationery_app.iml
```

All application code is contained in `lib/main.dart`. Firebase platform configuration is generated in `lib/firebase_options.dart`.

---

## Features

- User authentication with login and registration (in-memory store)
- Real-time product listing via Firebase Realtime Database
- Product ratings with live average calculation written back to Firebase
- Customer review submission and display
- Shopping cart with quantity controls and subtotal calculation
- Drag-and-drop product cards onto a floating cart drop zone
- GPS-based delivery address detection with reverse geocoding
- Animated hero banner with per-user greeting
- Horizontal scrollable product rows (Top Rated, New Arrivals, Best Sellers)
- Category chip navigation bar
- Promotional banners between product sections
- Animated top-of-screen toast notifications
- Logout confirmation dialog
- Responsive layout capped at 800px for wider screens

---

## Architecture Overview

The application is structured as a single-file Flutter app using stateful widgets and Firebase listeners. There is no external state management library; state is managed locally via `setState` and passed down through callbacks.

```
main()
 └── MyApp (MaterialApp)
      └── AuthGate (StatefulWidget)
           ├── AuthScreen         — shown when no user is logged in
           └── ProductPage        — shown after successful login
                ├── HeroBanner
                ├── LocationBanner
                ├── CategoryChips
                ├── SectionHeading
                ├── PromoBanner
                └── Cart BottomSheet
```

---

## Screens and Components

### AuthGate

Manages the top-level routing between the authentication screen and the main product page. Holds the current username in state and passes login/logout callbacks to child widgets.

### AuthScreen

Provides a combined login and sign-up form with animated tab switching. Validates input length, password confirmation, and delegates credential checks to `UserStore`.

`UserStore` is an in-memory map of usernames to passwords. It is not persisted between sessions. Default accounts are `demo / demo123` and `admin / admin123`.

### ProductPage

The main shopping screen. It listens to the Firebase `products` node in real time and renders the full page layout including all banners, rows, and product cards.

Key responsibilities:
- Listening to Firebase and normalising product data
- Managing the cart list (`List<CartItem>`)
- Handling rating updates (written back to Firebase with recalculated average)
- Handling review submission (pushed as a new child under `products/{id}/reviews`)
- Opening the cart bottom sheet

### HeroBanner

A full-width decorative banner at the top of the product page showing a personalized greeting, the brand name, tagline, and promotional pills. Displays a hero image from assets with a gradient overlay and falls back to a painted widget (`_HeroFallback`) if the asset is missing.

### LocationBanner

Requests GPS permission at the tap of a button, retrieves the device's current coordinates via `Geolocator`, and reverse-geocodes them into a human-readable address using the `geocoding` package. Displays latitude, longitude, and GPS accuracy alongside the resolved address.

### CategoryChips

A horizontally scrollable row of category filter chips (Pens & Pencils, Notebooks, Art Supplies, etc.). Currently display-only; filtering logic can be wired in by connecting each chip to a product list filter.

### SectionHeading

A reusable heading widget that renders a title, optional subtitle, and optional icon with a short decorative underline bar.

### PromoBanner

A full-width banner widget used between product sections to display promotional messages such as the free delivery threshold and gift set promotions.

### PenzyToast

A globally accessible overlay toast that slides in from the top of the screen with a fade and spring animation. Used for cart feedback, rating confirmation, and review submission acknowledgement.

---

## Firebase Integration

The app uses **Firebase Realtime Database**. Products are stored at the root `products` node with the following structure:

```json
{
  "products": {
    "<product_id>": {
      "name": "Product Name",
      "price": 299,
      "rating": 4.2,
      "users": 15,
      "image": "filename.jpg",
      "reviews": {
        "<review_id>": {
          "text": "Review content here"
        }
      }
    }
  }
}
```

**Rating updates** are computed client-side using the existing average and count, then written back as a single update to avoid a full rewrite.

**Reviews** are appended using `push()`, which generates a unique key under each product's `reviews` node.

Firebase is initialised in `main()` using `DefaultFirebaseOptions.currentPlatform` from the generated `firebase_options.dart` file.

---

## Location Services

Location detection is handled by the `LocationService` class, which wraps `Geolocator` and `geocoding`:

1. Checks whether location services are enabled on the device.
2. Requests permission if not already granted.
3. Retrieves the current position at high accuracy.
4. Reverse-geocodes the coordinates into a formatted address string.

The `LocationBanner` widget manages the UI state (loading, error, address detected) and exposes a Detect/Refresh button.

---

## Design System

All design tokens are centralised in the `P` class:

| Token       | Hex       | Usage                        |
|-------------|-----------|------------------------------|
| `cream`     | `#FDF8F2` | Page background              |
| `creamDark` | `#F5EDE0` | Input backgrounds, tab bar   |
| `sage`      | `#8BAF8B` | Primary action colour        |
| `sageDark`  | `#5E7D5E` | Prices, confirmed states     |
| `rose`      | `#D4836A` | Errors, delete actions       |
| `blush`     | `#EBB8A4` | Taglines, accent details     |
| `navy`      | `#1F2D3D` | App bar, cart bar, buttons   |
| `amber`     | `#F6B554` | Stars, rating highlights     |
| `lavender`  | `#B8A9D4` | Reviews section              |
| `white`     | `#FEFCF8` | Cards, overlays              |
| `textDark`  | `#2C1A0E` | Primary text                 |
| `textMid`   | `#7A6652` | Secondary text               |
| `textLight` | `#B8A898` | Hints, labels                |
| `border`    | `#EDE0D0` | Card and input borders       |

The app uses **Georgia** as its primary font family for headings and brand text.

---

## Dependencies

Add the following to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.x.x
  firebase_database: ^11.x.x
  geolocator: ^13.x.x
  geocoding: ^3.x.x
```

Refer to `pubspec.lock` for the exact resolved versions used in this project.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x or later
- A Firebase project with Realtime Database enabled
- `flutterfire` CLI for generating `firebase_options.dart`

### Setup

1. Clone the repository.

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase using the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` for your target platforms.

4. Set your Firebase Realtime Database rules to allow read and write access during development:
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```

5. Add product data to the `products` node in your Firebase Console following the schema described in the Firebase Integration section above.

6. Place product images in `assets/images/` and declare the directory in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```

7. Run the app:
   ```bash
   flutter run
   ```

### Platform-Specific Permissions

**Android** — add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to detect your delivery address.</string>
```

---

## Default Credentials

The following accounts are pre-seeded in the in-memory `UserStore` for testing:

| Username | Password |
|----------|----------|
| demo     | demo123  |
| admin    | admin123 |

These credentials reset on every app restart. Accounts registered during a session are also lost on restart as there is no persistence layer for authentication.

---

## Assets

The app expects the following asset for the hero banner:

```
assets/images/hero_banner.jpg
```

If this file is missing, the app renders `_HeroFallback`, a painted widget with decorative blobs and stationery icon overlays, so the UI remains fully functional without the image.

Product images are referenced by filename from the Firebase `image` field and loaded from `assets/images/`. Missing images fall back gracefully to a placeholder icon.