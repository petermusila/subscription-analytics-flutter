# Subscription Analytics Platform

A complete subscription analytics system built with Flutter and Supabase.

## Features

- ✅ User authentication (signup/login) with referral source tracking
- ✅ 4 subscription plans: Weekly ($3.99), Monthly ($12.99), Annual ($99.99), Lifetime ($249.99)
- ✅ Real-time analytics dashboard with:
  - MRR (Monthly Recurring Revenue)
  - Churn rate calculation
  - Active subscriptions by plan
  - 6-month revenue trend chart
- ✅ User profile with metadata (country, referral source, device type)
- ✅ Simulated data generation via GitHub Actions

## Tech Stack

- **Frontend:** Flutter (Web, iOS, Android)
- **Backend:** Supabase (PostgreSQL with RLS)
- **Automation:** GitHub Actions (daily data generation)


## GitHub Actions

Runs daily at 6:00 AM UTC, generating 15 new simulated users with random subscriptions and payment history.

## Database Schema

- `users` - User profiles with referral source and device tracking
- `subscriptions` - Subscription plans and status
- `payments` - Payment history linked to subscriptions

## Running Locally

```bash
flutter pub get
flutter run"# subscription-analytics" 
