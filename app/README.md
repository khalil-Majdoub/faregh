# Feregh (Flutter + Dart)

**Feregh** is a real-time queue waiting-time app covering **all 24 governorates of Tunisia** — including `La Poste Tunisie`, hospitals (`CHU` & regional hospitals), banks (`BIAT`, `STB`, `BNA`), municipalities, and utilities (`STEG`, `CNAM`), plus live **OpenStreetMap Overpass API** discovery for any area in Tunisia.

## Features

- **All 24 Governorates of Tunisia + Live OpenStreetMap Scan**:
  - 120+ real named Tunisian establishments across all 24 governorates (`Tunis` to `Tataouine`, `Bizerte` to `Tozeur`) available immediately offline.
  - One-tap **Scan area (OpenStreetMap Overpass API)** to dynamically load additional real Post Offices, Hospitals, Banks, and Municipalities anywhere you pan in Tunisia.
- **Real-Time Waiting Time Formula** (`5 min` per person):
  $$\text{Waiting People} = \max(0, \text{Last Ticket} - \text{Processing Ticket})$$
  $$\text{People per Guichet} = \frac{\text{Waiting People}}{\text{Active Guichets}}$$
  $$\text{Wait Time (min)} = \text{People per Guichet} \times 5$$
- **Automatic Periodic Recalculation**: Runs automatically every **2 minutes** or **5 minutes** via `Timer.periodic`.
- **Color-Coded Crowd Levels**:
  - **Green (`Not Crowded`)**: `< 20 min`
  - **Yellow (`Moderate`)**: `20 – 39 min`
  - **Red (`Crowded`)**: `≥ 40 min`
- **Mandatory Account System**: Sign in or create an account as a **Citizen** or **Establishment (Staff)** in any of Tunisia's 24 governorates.
- **Citizen Interface**:
  - Home screen with search (`post`, `hospital`, `bank`, `STEG`, city name...), category & crowd color filters, governorate selector, and a **Fastest nearby** recommendation card using Haversine distance + wait time.
  - Interactive **OpenStreetMap** tab (`flutter_map`) with Red / Yellow / Green pins, GPS blue beacon, All-Tunisia overview button, and live area scanning.
- **Establishment / Staff Interface**:
  - Side-by-side ticket desk to manage **Serving now**, **Last ticket**, and **Open guichets**, updating citizen views and map pins immediately.

## Demo Accounts

- **Citizen**: `khalil@user.tn` / `123456`
- **Establishment (LA POSTE - Sousse Centre)**: `poste@society.tn` / `123456`

## Getting Started

```bash
flutter pub get
flutter test
flutter run -d chrome
```
