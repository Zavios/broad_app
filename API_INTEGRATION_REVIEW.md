# Broad App — Backend API Integration Gap Analysis & Implementation Plan

> **Document Version:** 2.0.0  
> **Date:** November 2026  
> **Status:** Implementation in Progress (Core Work Complete — ~85% Finished)  
> **Scope:** Full integration of Broad Backend APIs into `broad_app` (Flutter)

---

## 1. Executive Summary

This document presents the updated audit of the **Broad Flutter application (`broad_app`)** against the **Broad Backend API Specification** following major Phase 1, 2, 4, and 5 integrations.

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
   - `RidesListPage`: Converted to reactive `ConsumerStatefulWidget`, calls `/api/rides/search`, handles loading/empty/error states, pull-to-refresh.
   - `RideCard`: Fixed stop naming (`locationName`), verification badge, initials avatar, theme consistency.
   - `RideDetailsPage`: Newly built (`lib/pages/search/ride_details_page.dart`) displaying route timeline, driver card, seats, and full booking flow with pickup/dropoff selector, seat stepper, and `POST /api/rides/:rideId/book`.
5. **My Rides Management (Complete):**
   - `MyRidesPage`: Completely implemented with dual tabs:
     - **Driver Tab:** Lists published rides (`/api/rides/my/published`), allows ride cancellation (`/api/rides/:id/cancel`), and opens booking requests sheet (`/api/rides/:id/bookings`) with "Confirm" / "Reject" actions (`/api/rides/:id/booking/:id`).
     - **Passenger Tab:** Lists user bookings (`/api/rides/my/bookings`) with status badges (`pending`, `confirmed`, `rejected`, `cancelled`) and cancel booking actions.
6. **Publish Ride Flow (Partially Complete):**
   - `PostRideData`: Updated with coordinates and polyline fields.
   - `FareAndPassengerPage`: Fetches user vehicles dynamically from `vehicleProvider`, constructs origin & destination `stops` array, submits payload to `POST /api/rides`.
   - **Remaining:** Google Maps autocomplete sheet and live route calculation in `routes_page.dart` using `/api/maps/routes`.

---

## 2. API Endpoints vs Implementation Status Matrix

The backend defines **24 core API endpoints** across 4 modules (31 total with aliases/actions). Below is the itemized integration status for each:

| #      | Endpoint                                | Method   | Purpose                                  | Service Built? | Provider Built? | UI Integrated? | Status / Action Taken                                                  |
| ------ | --------------------------------------- | -------- | ---------------------------------------- | :------------: | :-------------: | :------------: | ---------------------------------------------------------------------- |
| **1**  | `/api/auth/signup`                      | `POST`   | Register new user in Supabase            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `signup_page.dart` with email verification check       |
| **2**  | `/api/auth/signin`                      | `POST`   | Sign in with email & password            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `login_page.dart` with token persistence & error alerts|
| **3**  | `/api/auth/google`                      | `GET`    | Get Google OAuth authorization URL       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** via `url_launcher` on Login & Signup screens             |
| **4**  | `/api/auth/callback`                    | `GET`    | Exchange OAuth code for tokens           |     ✅ Yes     |     ✅ Yes      |   ⚠️ Partial   | Handler ready in `AuthNotifier`; deep link scheme hook pending          |
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
| **16** | `/api/maps/routes`                      | `POST`   | Compute route alternatives & polyline    |     ✅ Yes     |     ✅ Yes      |     ❌ No      | To wire in `routes_page.dart` replacing dummy grid                     |
| **17** | `/api/maps/distance`                    | `POST`   | Get distance & duration only             |     ✅ Yes     |     ✅ Yes      |     ❌ No      | Ready for quick trip distance badges                                   |
| **18** | `/api/maps/geocode`                     | `GET`    | Forward geocode address string to coords |     ✅ Yes     |     ✅ Yes      |   ⚠️ Partial   | Location dialog geocoding integration                                  |
| **19** | `/api/maps/reverse-geocode`             | `GET`    | Reverse geocode lat/lng to address       |     ✅ Yes     |     ✅ Yes      |     ❌ No      | Ready for GPS current location pin                                     |
| **20** | `/api/maps/autocomplete`                | `GET`    | Place autocomplete suggestions           |     ✅ Yes     |     ✅ Yes      |     ❌ No      | Build bottom sheet suggestion list for `SearchPage` & `PostPage`       |
| **21** | `/api/rides/search`                     | `GET`    | Search published active rides            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `rides_list_page.dart` with filter parameters         |
| **22** | `/api/rides/my/published`               | `GET`    | List rides published by driver           |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Driver tab                              |
| **23** | `/api/rides/my/bookings`                | `GET`    | List bookings made by passenger          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Passenger tab                           |
| **24** | `/api/rides`                            | `POST`   | Publish ride with stops array            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `fare_and_passenger_page.dart`                        |
| **25** | `/api/rides/:rideId`                    | `GET`    | Fetch specific ride & stops detail       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `ride_details_page.dart`                              |
| **26** | `/api/rides/:rideId`                    | `PATCH`  | Update ride (date, price, seats)         |     ✅ Yes     |     ✅ Yes      |     ❌ No      | Optional driver ride editor                                            |
| **27** | `/api/rides/:rideId/cancel`             | `POST`   | Driver cancels published ride            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Driver tab with dialog confirmation     |
| **28** | `/api/rides/:rideId/book`               | `POST`   | Passenger requests tag-along seats       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `RideDetailsPage` Booking Sheet                       |
| **29** | `/api/rides/:rideId/bookings`           | `GET`    | Driver views booking requests            |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Booking Requests modal                  |
| **30** | `/api/rides/:rideId/booking/:id`        | `PATCH`  | Driver Confirms or Rejects booking       |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` with Confirm/Reject action buttons      |
| **31** | `/api/rides/:rideId/booking/:id/cancel` | `POST`   | Passenger cancels their booking          |     ✅ Yes     |     ✅ Yes      |     ✅ Yes     | **Completed** in `MyRidesPage` Passenger tab                           |

---

## 3. Implemented Modules Walkthrough

### 3.1 App Foundation & Startup (`lib/main.dart`)
- `ProviderScope` now wraps the root application widget.
- Added `_AuthGate` widget as `home:`:
  - Invokes `ref.read(authProvider.notifier).checkAuthStatus()`.
  - Displays circular progress indicator while resolving.
  - Automatically navigates to `Homepage` on valid session or `LandingPage` if unauthenticated.

### 3.2 Authentication (`lib/pages/auth_and_signup/`)
- **`login_page.dart`:**
  - Removed unconditional route push.
  - Form validation enforced.
  - `ref.read(authProvider.notifier).signIn(email, password)` called with button loading spinner.
  - SnackBar error reporting directly from API response (`DioException`).
  - Google OAuth triggered with `url_launcher`.
- **`signup_page.dart`:**
  - Integrated `authProvider.notifier.signUp(email, password)`.
  - Handles pending email confirmation with an informative modal dialog.
  - Google OAuth integrated.
- **`profile_details_page.dart`:**
  - Added required `username` field.
  - Formats `dob` as `YYYY-MM-DD`.
  - Strips non-digits from `phone` and passes valid integer smallint.
  - Submits to `profileProvider.createProfile()`. Handles 409 conflict.

### 3.3 Profile & Vehicles (`lib/pages/profile/profile_page.dart`)
- Fetches real data using `profileService.getMyProfile()` and `getMyVehicles()`.
- Replaced mock user strings and mock vehicle cards.
- Add Vehicle modal calls `addVehicle(...)`.
- Delete vehicle icon triggers confirmation dialog and `deleteVehicle(id)`.
- Edit dialogs update phone and bio via `updateProfile(...)`.
- Added Sign Out button that revokes session and clears secure storage.

### 3.4 Search, Results & Booking (`lib/pages/search/`)
- **`rides_list_page.dart`:**
  - Replaced static placeholder with `searchRidesProvider`.
  - Passes `departure_date` and `min_seats` to `/api/rides/search`.
  - Provides pull-to-refresh, empty state, and error retry.
  - Tapping any `RideCard` opens `RideDetailsPage`.
- **`ride_details_page.dart` (New):**
  - Fetches ride via `getRideById(rideId)`.
  - Displays driver card with verification status and initials avatar.
  - Displays ordered stop timeline (origin, stops, destination).
  - Displays price, available seats, and notes.
  - "Request Tag Along" opens booking modal with pickup/dropoff stop selection, seat counter, and calls `bookRide()`.

### 3.5 My Rides Management (`lib/pages/my_rides/my_rides_page.dart`)
- Converted from an empty stub to a full two-tab dashboard:
  - **Driver Tab:**
    - Loads published rides via `/api/rides/my/published`.
    - Active rides show "Requests" and "Cancel Ride" actions.
    - "Requests" opens a sheet fetching `/api/rides/:id/bookings`, allowing the driver to tap "Confirm" or "Reject" (`respondToBooking`).
    - "Cancel Ride" prompts for confirmation and calls `/api/rides/:id/cancel`.
  - **Passenger Tab:**
    - Loads bookings via `/api/rides/my/bookings`.
    - Shows status badges (`PENDING`, `CONFIRMED`, `REJECTED`, `CANCELLED`).
    - Provides a "Cancel Booking" action for pending/confirmed bookings via `/api/rides/:id/booking/:id/cancel`.

### 3.6 Publish Ride Flow (`lib/pages/post/fare_and_passenger_page.dart`)
- Dynamically loads registered vehicles from `vehicleProvider`.
- If no vehicles exist, guides the user to register one in Profile.
- Constructs standard stops array (`origin` at stop 1, `destination` at stop 2).
- Submits to `/api/rides` via `publishRideProvider`.
- Navigates back to home and presents a summary confirmation banner.

---

## 4. Remaining Tasks to Reach 100%

1. **Google Maps Autocomplete & Geocoding Component:**
   - Create `lib/components/location_search_sheet.dart` consuming `autocompleteProvider` (`/api/maps/autocomplete`) and `MapsService.geocode()`.
   - Wire into `PostPage` and `SearchPage` location pickers so exact coordinates (`lat`, `lng`) are captured.
2. **Dynamic Route Alternatives in `routes_page.dart`:**
   - Call `/api/maps/routes` with origin and destination coordinates.
   - Replace the dummy 4-button grid with dynamically calculated route options showing distance and duration.
3. **Deep Link Callback Scheme:**
   - Configure Android/iOS URL schemes for `broad://auth/callback` to finalize Google OAuth deep linking.

---

## 5. Summary Checklist

- [x] **Dependencies:** Installed and configured (`dio`, `flutter_riverpod`, `flutter_secure_storage`, `url_launcher`).
- [x] **App Setup:** Wrapped `main.dart` in `ProviderScope` and created `_AuthGate`.
- [x] **Auth Flow:** Login, Signup, Profile Details, and Sign Out fully connected to API.
- [x] **Profile & Vehicles:** Live profile details, vehicle CRUD, and logout in `ProfilePage`.
- [x] **Ride Search:** Reactive search results in `RidesListPage`.
- [x] **Ride Details & Booking:** Built `RideDetailsPage` and Tag-Along Booking flow.
- [x] **My Rides Dashboard:** Dual Driver/Passenger tabs with ride cancellation, booking requests, and approvals/rejections.
- [x] **Publish Ride:** Real vehicle dropdown and ride submission in `FareAndPassengerPage`.
- [ ] **Location Search Sheet:** Autocomplete search with Google Maps places API.
- [ ] **Routes Calculation:** Live polyline and route calculation in `RoutesPage`.
