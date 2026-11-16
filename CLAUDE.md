# CLAUDE.md — Frigo Autonomous Development Rules

## Project Overview
- **App Name:** Frigo — "Cook with what you already have."
- **Platform & Stack:** Flutter, Dart, `flutter_riverpod` (state management), `go_router` (navigation), clean repository pattern backed by JSON in `shared_preferences` behind a `LocalStore` abstraction (designed for easy swap to Firebase / Vision OCR later).
- **Supported Platforms:** iOS, macOS desktop, and Android are all first-class targets. Every feature must build and run on all three.
- **Core Loop:** Add ingredients -> View visual fridge -> Get ranked matching recipes -> Cook with step-by-step timers -> Add missing ingredients to shopping list.

## Roadmap Status
- **Phase 0 — Core app (complete):** All 9 screens + Recipe Detail and Cooking Mode, recipe matching & allergy engine, appliance-realism fridge/door redesign (`TASKS.md` Tasks 1–10).
- **Phase 1 — Persistence & physical UX (complete):** JSON-backed `shared_preferences` persistence for fridge, shopping notes and profile with first-launch seeding and `Reset demo data`; `HapticFeedback.lightImpact()` on fridge taps, checkbox toggles and cooking step navigation; `wakelock_plus` keeps the screen awake in Cooking Mode; live `Items saved` impact counter on Profile (Tasks 11–12). Suite: 131 passing tests, zero analyzer issues.
- **Phase 2 — Scanning & notifications (next):** Real barcode and receipt scanning feeding `5. Check what we found` (replacing the mock detections), and local expiry notifications for items nearing their date.

## Cross-Platform Rules
- `main()` must call `WidgetsFlutterBinding.ensureInitialized()` before any plugin access (e.g. `SharedPreferences.getInstance()`).
- Only add plugins that support iOS, macOS and Android; if a capability is missing on one platform (e.g. camera scanning on macOS desktop), provide a graceful fallback such as image/file import or manual entry — never a crash or dead route.
- Declare required permissions per platform when adding Phase 2 plugins: `Info.plist` usage strings on iOS/macOS (camera, notifications), macOS sandbox entitlements (`macos/Runner/*.entitlements`), and `AndroidManifest.xml` permissions (camera, `POST_NOTIFICATIONS`).
- Guard platform-specific behavior (haptics, wakelock, notifications) so it degrades silently where unsupported and stays mockable in tests.

## Visual Design System (Strict Adherence to Mockups)
- **App Background:** Soft Pale Sage `#F4F7F4`
- **Fridge Interior & Brand Accent:** Mint Green `#95C5B1`
- **Primary Text & Dark CTA Buttons:** Deep Forest Charcoal `#1A2421` (rounded rectangle `14px` radius or stadium pill)
- **Expiry Alert Banner & Badges:** Soft Coral Red `#E05A47` text/badge on `#FDECEC` surface (e.g. `1d`, `2d` badges)
- **Fridge Door Sticky Notes:** Pastel Yellow `#FFF3B0` and Pastel Pink `#FAD2D8`
- **Cards & Chips:** Pure White `#FFFFFF` cards with subtle `#E2E8E4` border; pill-shaped toggle chips.

## Screen & Feature Specifications (9 Screens + Cooking Mode)
1. **Login (`1. Login`):** Frigo logo, tagline "Cook with what you already have.", Email (`you@example.com`), Password, `Log in` dark button, `Continue with Google` outlined button, `Create an account` link (mock authentication).
2. **My Fridge Home (`2. My Fridge`):**
   - Header: Item count subtitle (`13 items`), fridge-door icon button (navigates to Shopping List), circular user avatar `EY` (navigates to Profile).
   - Top alert banner: Highlights expiring items (e.g., "Yogurt and sea bass expire soon. Try cacik or baked sea bass today.").
   - Visual fridge container with 3 labeled shelves: `DAIRY`, `MEAT AND LEFTOVERS`, `VEGETABLE DRAWER`.
   - Bottom action row: `+ Add ingredients` (outlined) and `Suggest recipes` (dark CTA).
3. **Shopping List (`3. Shopping list`):**
   - Subtitle: "Notes on your fridge door", avatar `EY`.
   - Sticky note cards grouped by recipe or category (e.g., yellow note "For cacık": Cucumber, Garlic, Dried mint; pink note "Weekly": Milk, Bread) with interactive checkboxes.
   - `+ Add a note` button, helper text "Missing ingredients from recipes land here automatically.", bottom `Open the fridge` dark CTA.
4. **Add Ingredients (`4. Add ingredients`):**
   - `Take a photo` card & `Scan a receipt` card (both route to Scan Confirmation with realistic mock detected ingredients).
   - Manual entry section (`OR TYPE IT IN`): Ingredient text field with quick suggestion chips (e.g., `Spinach`, `Spinach, frozen`), optional Expiry date field (`e.g. 20 Nov`), and `Add to fridge` dark CTA.
5. **Scan Confirmation (`5. Check what we found`):**
   - Photo preview box, found count ("5 ingredients found. Untick anything that is wrong.").
   - Checkable list showing ingredient name and assigned shelf (`Vegetable drawer`, `Dairy`, `Not added`), inline `Add something we missed` input with `+` button, and `Save X to my fridge` dark CTA.
6. **Recipe Suggestions (`6. What to cook`):**
   - Filter chips: `Allergy-safe`, `Under 20 min`, `Vegetarian`, `Uses expiring`.
   - Ranked recipe cards showing thumbnail placeholder, title, cook time, expiry priority note, match % badge (e.g., `100% match`, `80% match – missing garlic`), favorite heart toggle, and one-tap action to add missing ingredients to Shopping List.
   - Strictly hide recipes containing any user allergen and show bottom summary (e.g., "Hidden: 2 recipes with peanuts (your allergy)").
7. **Recipe Detail & Cooking Mode:**
   - Tapping a recipe opens ingredients & steps with a `Start Cooking` button.
   - **Cooking Mode:** Step-by-step guided view where every step includes an interactive countdown timer (start, pause, reset) and Next/Previous step controls.
8. **Profile (`7. Profile`):**
   - Avatar `EY`, name `Elif Yılmaz`, email `elif@example.com`.
   - 3 stat cards: `Favorites`, `Meals cooked`, `Items saved`.
   - Menu tiles: `Favorite recipes`, `Allergies and diet` (showing active tags like `Peanuts`, `Lactose`), `Shopping list` (item count), and `Log out` button.
9. **Favorite Recipes (`8. Favorite recipes`):**
   - Search bar (`Search your favorites`), 2-column grid of favorite recipe cards with `Ready` green pill badge when 100% of ingredients are in the fridge, cook time, cooked count, or missing count.
10. **Allergies and Diet (`9. Allergies and diet`):**
    - Warning banner ("Recipes with these ingredients are hidden from your suggestions.").
    - `I'm allergic to` multi-select chips: `Peanuts`, `Tree nuts`, `Milk`, `Eggs`, `Gluten`, `Fish`, `Shellfish`, `Soy`, `Sesame`, plus custom ingredient addition (`Add your own ingredient`).
    - `My diet` single-select chips: `None`, `Vegetarian`, `Vegan`, `Halal`, and `Save` dark CTA.

## Coding & Verification Standards
- Organize code cleanly under `lib/core/`, `lib/models/`, `lib/data/`, `lib/providers/`, and `lib/features/`.
- Never leave `TODO` comments, stub screens, or broken routes.
- Before marking any task `[x]` in `TASKS.md`, run `flutter analyze` and `flutter test` and ensure zero errors.
- Commit each completed task separately with a clear commit message.
