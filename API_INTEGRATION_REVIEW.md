# Broad App — Backend API Integration Gap Analysis & Implementation Plan

> **Document Version:** 3.0.0  
> **Date:** November 2026  
> **Status:** API Integration 100% Complete (Core Scope Finished)  
> **Scope:** Full integration of Broad Backend APIs into `broad_app` (Flutter)

---

## 1. Executive Summary

This document confirms the **100% completion of the core Backend API Integration** in the **Broad Flutter application (`broad_app`)**. All UI screens, forms, search flows, ride posting flows, booking flows, and Google Maps services are fully connected to live backend APIs.

### Current Implementation State:

1. **Foundation & Architecture (Complete):**
   - `main.dart` is wrapped in Riverpod's `ProviderScope(child: MyApp())`.
   - Added `_AuthGate` on launch to verify stored session via `checkAuthStatus()` and auto-route to `Homepage` or `LandingPage`.
   - Dio client (`api_client.dart`) with secure token storage (`flutter_secure_storage`) and auto-refresh interceptor configured.
2. **Authentication & Profile Setup (Complete):**
   - `LoginPage`: Connected to `authProvider.signIn()`, loading state indicator, API error handling, Google OAuth via `url_launcher`.
   - `SignupPage`: Connected to `authProvider.signUp()`, email confirmation dialog, Google OAuth.
   - `ProfileDetailsPage`: Connected to `profileProvider.createProfile()`, added `username` field, formatted date as `YYYY-MM-DD`, formatted phone as integer.
3. **Profile & Vehicles Management (Complete):**
   - `ProfilePage`: Rewritten to fetch live user profile (`/api/profile/me`) and vehicle fleet (`/api/profile/vehicle`).
   - Add/edit/delete vehicles connected directly to API.
   - Profile field edits connected to `PATCH /api/profile`.
   - Sign-out flow connected to `/api/auth/signout` and token clearing.
4. **Search, Ride Details & Tag-Along Booking (Complete):**
   - `SearchPage`: Integrated with live Google Maps place autocomplete bottom sheet (`location_search_sheet.dart`).
   - `RidesListPage`: Converted to reactive `ConsumerStatefulWidget`, calls `/api/rides/search`, handles loading/empty/error states, pull-to-refresh.
   - `RideCard`: Fixed stop naming (`locationName`), verification badge, initials avatar, theme consistency.
   - `RideDetailsPage`: Newly built (`lib/pages/search/ride_details_page.dart`) displaying route timeline, driver card, seats, and full booking flow with pickup/dropoff selector, seat stepper, and `POST /api/rides/:rideId/book`.
5. **My Rides Management (Complete):**
   - `MyRidesPage`: Completely implemented with dual tabs:
     - **Driver Tab:** Lists published rides (`/api/rides/my/published`), allows ride cancellation (`/api/rides/:id/cancel`), and opens booking requests sheet (`/api/rides/:id/bookings`) with "Confirm" / "Reject" actions (`/api/rides/:id/booking/:id`).
     - **Passenger Tab:** Lists user bookings (`/api/rides/my/bookings`) with status badges (`pending`, `confirmed`, `rejected`, `cancelled`) and cancel booking actions.
6. **Publish Ride Flow (Complete):**
   - `PostPage`: Location pickers open live Google Maps place autocomplete (`location_search_sheet.dart`) and capture exact latitude/longitude coordinates.
   - `RoutesPage`: Calls `/api/maps/routes` with origin & destination coordinates, displays an interactive `GoogleMap` with origin/destination markers and decoded route polylines (`flutter_polyline_points`), and renders selectable route cards with distance and duration.
   - `PostRideData`: Carries origin/destination coordinates and selected route polyline across navigation steps.
   - `FareAndPassengerPage`: Fetches user vehicles dynamically from `vehicleProvider`, constructs origin & destination `stops` array, submits full payload (including polyline) to `POST /api/rides`.

---

## 2. API Endpoints vs Implementation Status Matrix

The backend defines **24 core API endpoints** across 4 modules (31 total with aliases/actions). Below is the itemized integration status for each:

| #      | Endpoint                                | Method   | Purpose                                  | Service Built? | Provider Built? | UI Integrated? | Status / Action Taken                                                  |
| ------ | --------------------------------------- | -------- | ---------------------------------------- | :------------: | :-------------: | :------------: | ---------------------------------------------------------------------- |
| **1**  | `/api/auth/signup`                      | `POST`   | Register new user in Supabase            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `signup_page.dart` with email verification check       |
| **2**  | `/api/auth/signin`                      | `POST`   | Sign in with email & password            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `login_page.dart` with token persistence & error alerts|
| **3**  | `/api/auth/google`                      | `GET`    | Get Google OAuth authorization URL       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** via `url_launcher` on Login & Signup screens             |
| **4**  | `/api/auth/callback`                    | `GET`    | Exchange OAuth code for tokens           |     ✅ Yes     |     ✅ Yes      |   ⏸️ Deferred  | Handler ready in `AuthNotifier`; deep link URI scheme deferred         |
| **5**  | `/api/auth/refresh`                     | `POST`   | Refresh expired JWT access token         |     ✅ Yes     |     ✅ Auto     |     ✅ Yes     | **Completed** in `ApiClient` Dio interceptor                           |
| **6**  | `/api/auth/signout`                     | `POST`   | Invalidate current user session          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `ProfilePage` logout button                           |
| **7**  | `/api/auth/me`                          | `GET`    | Fetch authenticated user details         |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `_AuthGate` in `main.dart` for auto-login             |
| **8**  | `/api/profile`                          | `POST`   | Create initial user profile              |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_details_page.dart`                           |
| **9**  | `/api/profile/me`                       | `GET`    | Retrieve logged-in user profile          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_page.dart` live fetch                        |
| **10** | `/api/profile/:id`                      | `GET`    | Get public profile (sanitized)           |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `RideDetailsPage` driver card                         |
| **11** | `/api/profile`                          | `PATCH`  | Update mutable profile fields            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_page.dart` edit dialogs                      |
| **12** | `/api/profile/vehicle`                  | `POST`   | Register a new vehicle                   |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_page.dart` "Add Vehicle" modal               |
| **13** | `/api/profile/vehicle`                  | `GET`    | List all vehicles owned by user          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `ProfilePage` & `FareAndPassengerPage` dropdown       |
| **14** | `/api/profile/vehicle/:id`              | `PATCH`  | Update vehicle attributes                |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_page.dart` vehicle options                   |
| **15** | `/api/profile/vehicle/:id`              | `DELETE` | Delete a registered vehicle              |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `profile_page.dart` delete flow                       |
| **16** | `/api/maps/routes`                      | `POST`   | Compute route alternatives & polyline    |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `routes_page.dart` with interactive Google Map        |
| **17** | `/api/maps/distance`                    | `POST`   | Get distance & duration only             |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MapsService` & `routes_page.dart`                    |
| **18** | `/api/maps/geocode`                     | `GET`    | Forward geocode address string to coords |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `location_search_sheet.dart` on suggestion tap        |
| **19** | `/api/maps/reverse-geocode`             | `GET`    | Reverse geocode lat/lng to address       |     ✅ Yes     |     ✅ Yes      |     ✅ Ready   | Built in `MapsService` for future GPS pin features                     |
| **20** | `/api/maps/autocomplete`                | `GET`    | Place autocomplete suggestions           |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `location_search_sheet.dart` for Search & Post pages  |
| **21** | `/api/rides/search`                     | `GET`    | Search published active rides            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `rides_list_page.dart` with filter parameters         |
| **22** | `/api/rides/my/published`               | `GET`    | List rides published by driver           |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Driver tab                              |
| **23** | `/api/rides/my/bookings`                | `GET`    | List bookings made by passenger          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Passenger tab                           |
| **24** | `/api/rides`                            | `POST`   | Publish ride with stops array            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `fare_and_passenger_page.dart`                        |
| **25** | `/api/rides/:rideId`                    | `GET`    | Fetch specific ride & stops detail       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `ride_details_page.dart`                              |
| **26** | `/api/rides/:rideId`                    | `PATCH`  | Update ride (date, price, seats)         |     ✅ Yes     |     ✅ Yes      |     ✅ Ready   | Built in `RidesService`                                                |
| **27** | `/api/rides/:rideId/cancel`             | `POST`   | Driver cancels published ride            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Driver tab with dialog confirmation     |
| **28** | `/api/rides/:rideId/book`               | `POST`   | Passenger requests tag-along seats       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `RideDetailsPage` Booking Sheet                       |
| **29** | `/api/rides/:rideId/bookings`           | `GET`    | Driver views booking requests            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Booking Requests modal                  |
| **30** | `/api/rides/:rideId/booking/:id`        | `PATCH`  | Driver Confirms or Rejects booking       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` with Confirm/Reject action buttons      |
| **31** | `/api/rides/:rideId/booking/:id/cancel` | `POST`   | Passenger cancels their booking          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Passenger tab                           |

---

## 3. Summary Checklist

- [x] **Dependencies:** Installed and configured (`dio`, `flutter_riverpod`, `flutter_secure_storage`, `url_launcher`, `google_maps_flutter`, `flutter_polyline_points`).
- [x] **App Setup:** Wrapped `main.dart` in `ProviderScope` and created `_AuthGate`.
- [x] **Auth Flow:** Login, Signup, Profile Details, and Sign Out fully connected to API.
- [x] **Profile & Vehicles:** Live profile details, vehicle CRUD, and logout in `ProfilePage`.
- [x] **Ride Search:** Reactive search results in `RidesListPage`.
- [x] **Ride Details & Booking:** Built `RideDetailsPage` and Tag-Along Booking flow.
- [x] **My Rides Dashboard:** Dual Driver/Passenger tabs with ride cancellation, booking requests, and approvals/rejections.
- [x] **Publish Ride:** Real vehicle dropdown and ride submission in `FareAndPassengerPage`.
- [x] **Location Search Sheet:** Autocomplete search with Google Maps places API (`location_search_sheet.dart`).
- [x] **Routes Calculation:** Live polyline, GoogleMap widget, and route calculation in `routes_page.dart`.
- [ ] **Deferred by Request:** Google OAuth deep link scheme (`broad://auth/callback`).
