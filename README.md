# INDIEGO Mobile Client

INDIEGO Mobile Client is a Flutter-based marketplace application for discovering indie games and game assets.

This project was prepared as an individual submission for the Mobile Programming course. The application focuses on a practical mobile user experience: authentication, browsing products, viewing product details, managing wishlist and cart items, and accessing account-related screens.

## Features

- User authentication
  Login and registration screens connected to a backend API.
- Home and store browsing
  Featured games, new releases, and popular assets are displayed on mobile-friendly screens.
- Games and assets listing
  Users can browse products, search, filter, and sort them.
- Product detail pages
  Each game or asset can be viewed in detail with images, description, and review-related information.
- Wishlist and cart
  Products can be added to and removed from wishlist and cart screens.
- Profile and settings
  User profile information and settings-related screens are available in the app.
- Seller overview
  A lightweight mobile seller dashboard is included for preview and monitoring purposes.

## Project Scope

This mobile application is intentionally focused on the parts that make sense on a phone:

- browsing products
- viewing details
- interacting with wishlist and cart
- accessing account-side screens

Advanced workflows such as full product upload, detailed seller management, and desktop-style operational tasks are outside the main scope of this mobile version.

## Tech Stack

- Flutter
- Dart
- HTTP-based backend integration
- SharedPreferences for local token/session storage

## Backend Integration

The app is designed to work with a backend API running locally during development.

Example base URL used in the project:

```text
https://localhost:9001
```

The mobile client consumes backend data for:

- authentication
- product listing
- product detail pages
- cart
- wishlist
- user profile
- seller product overview

## Demo/Test Account

The project was tested using the following account during development:

```text
basicuser@gmail.com
Basic123!
```

Depending on local backend/database state, this test account may also have seller permissions enabled.

## Running the Project

1. Start the backend API locally.
2. Make sure the database and required seed data are available.
3. Open the Flutter project.
4. Install dependencies:

```bash
flutter pub get
```

5. Run the application:

```bash
flutter run -d chrome
```

## Notes

- Product images in the demo can come either from backend URLs or from local app assets.
- Some screens are role-based, so a seller-authorized account can see additional sections such as the dashboard.
- The mobile app is designed as a mobile-first client, not as a full replacement for desktop management workflows.

## Repository Purpose

This repository contains the standalone Mobile Programming version of the INDIEGO Flutter application.

