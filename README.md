# RemindMD

A reminder app for meds, supplements, herbal remedies, and physical practices
(PT, meditation, etc.), plus a separate section for appointments and classes
(medical visits, therapy, yoga/fitness classes). Optionally tracks supply on
hand so you know when to reorder.

## Stack

- Flutter (Android, iOS, Web)
- Supabase (Postgres + Auth) via `supabase_flutter`
- `google_fonts` (Zilla Slab / Inter / IBM Plex Mono)
- `flutter_local_notifications` + `timezone` for scheduled reminders

## Setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` against it (SQL editor or `supabase db push`).
3. Run the app with your project's URL and anon/publishable key:

   ```sh
   flutter pub get
   flutter run \
     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

   Without these defines, the app shows a "Supabase isn't configured yet"
   screen instead of the login flow.

4. Sign up with an email/password on first launch (Supabase sends a
   confirmation email by default; you can disable that in
   Authentication → Providers → Email while developing).

## Structure

- `lib/models/` — Dart types mirroring `supabase/schema.sql`'s tables/enums.
- `lib/services/` — Supabase repositories and the local notification scheduler.
- `lib/screens/` — Today (day-rail timeline), Regimen, Appointments, Supply.
- `lib/widgets/` — Shared UI: the Add bottom sheet, dose/appointment rows, etc.
- `lib/theme/` — Design tokens (colors, fonts) carried over from the prototype.

## Reminder defaults

Set at creation time; editable per item/appointment afterwards.

| Modality | Reminder style |
|---|---|
| pharma / herbal | standard |
| supplement / practice | gentle |

| Appointment type | Reminder lead times |
|---|---|
| medical | 1 day + 1 hour before |
| therapy / class / other | 1 hour before |

## Notes on notifications

`NotificationService` schedules local notifications from each regimen item's
`fixed_times` and each appointment's `reminder_lead_minutes`. Every
create/edit/delete first cancels the entity's existing notifications before
(re)scheduling, so the on-device queue stays in sync with Supabase. If the
platform's notification service is unavailable (permissions denied, no
notification daemon, etc.), scheduling calls become no-ops instead of
crashing the app.
