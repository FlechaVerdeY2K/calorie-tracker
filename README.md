# Calorie Tracker

Protein-first nutrition tracker for Latin America. Built with Flutter, Supabase, and BLoC.

## Stack

- Flutter (Dart ≥3.5)
- Supabase (Auth, Postgres, Storage, Edge Functions)
- `flutter_bloc` + `dartz` + `get_it`/`injectable` + `go_router`
- Firebase Cloud Messaging (push notifications only)

## Getting started

1. Copy `.env.example` to `.env` and fill in your Supabase URL and anon key.
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter run`

## Docs

- `docs/DESIGN.md` — product and architecture
- `docs/SECURITY.md` — threat model, RLS, privacy
- `docs/MIGRATION_PLAN.md` — week-1 PR checklist

## Project structure

See `docs/DESIGN.md`. Follows Clean Architecture + feature-first organization.