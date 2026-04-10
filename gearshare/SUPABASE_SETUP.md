# GearShare Supabase Setup Guide

## 📋 Completed Setup

✅ **Installed Supabase Flutter packages:**
- `supabase_flutter: ^2.10.0`
- `http: ^1.1.0`

✅ **Created authentication pages:**
- Landing Page (`landingPage.dart`) - Get Started button
- Sign In Page (`pages/sign_in_page.dart`)
- Sign Up Page (`pages/sign_up_page.dart`)

✅ **Created Supabase service:**
- `services/supabase_service.dart` - Handles auth and database operations

✅ **Updated main.dart:**
- Initializes Supabase on app startup
- Sets up navigation routes

---

## 🔧 Next Steps: Configure Supabase

### 1. Create a Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Enter project name, database password, and region
4. Wait for project to be created

### 2. Get Your Credentials
1. In Supabase dashboard, go to **Settings → API**
2. Copy your:
   - **Project URL** (Supabase URL)
   - **Anon Key** (Supabase Anon Key)

### 3. Update Flutter App Configuration
Edit [lib/services/supabase_service.dart](lib/services/supabase_service.dart) and [lib/main.dart](lib/main.dart):

Replace:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual credentials from step 2.

### 4. Create Users Table in Supabase

In Supabase dashboard, go to **SQL Editor** and run this SQL command:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX idx_users_email ON users(email);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for users to read their own data
CREATE POLICY "Users can read their own data"
ON users FOR SELECT
USING (auth.uid() = id);

-- Create RLS policy for users to update their own data
CREATE POLICY "Users can update their own data"
ON users FOR UPDATE
USING (auth.uid() = id);

-- Create RLS policy for users to insert their own data
CREATE POLICY "Users can insert their own data"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);
```

### 5. Configure Authentication Settings (Optional but Recommended)

In Supabase dashboard:
1. Go to **Authentication → Providers**
2. Enable Email (should be enabled by default)
3. Go to **Authentication → Policies**
4. Configure email confirmation settings if desired

### 6. Install Dependencies
Run this command in your Flutter project:

```bash
cd gearshare
flutter pub get
```

### 7. Run Your App

```bash
flutter run
```

---

## 📱 App Flow

1. **Landing Page** → Click "Get Started"
2. **Sign In Page** → Enter email/password or click "Sign Up"
3. **Sign Up Page** → Fill in name, email, phone, password
4. **Home Page** → Success! User is authenticated

---

## 📧 Supabase Database Schema

### Users Table

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, references auth.users |
| email | VARCHAR | User's email |
| name | VARCHAR | User's full name |
| phone | VARCHAR | User's phone number |
| created_at | TIMESTAMP | Account creation time |
| updated_at | TIMESTAMP | Last update time |

---

## 🔒 Security Notes

- Row Level Security (RLS) policies are enabled
- Users can only read/update their own data
- Passwords are handled by Supabase Auth (never stored in users table)
- All sensitive operations use authenticated users only

---

## 🐛 Troubleshooting

**Q: Getting "Could not initialize Supabase" error?**
- Make sure you've added your credentials in `main.dart` and `supabase_service.dart`

**Q: Sign up works but Sign in fails?**
- Confirm the users table is created correctly
- Check that email/password are correct
- Verify RLS policies are set up

**Q: Phone number field appears but isn't saved?**
- Ensure the users table has the `phone` column
- Check the phone column type in database

---

## 📚 Files Created/Modified

- ✅ [pubspec.yaml](../pubspec.yaml) - Added Supabase packages
- ✅ [lib/main.dart](../main.dart) - Supabase initialization
- ✅ [lib/landingPage.dart](../landingPage.dart) - Get Started navigation
- ✅ [lib/pages/sign_in_page.dart](pages/sign_in_page.dart) - Sign in UI & logic
- ✅ [lib/pages/sign_up_page.dart](pages/sign_up_page.dart) - Sign up UI & logic
- ✅ [lib/services/supabase_service.dart](services/supabase_service.dart) - Supabase operations

---

Need help? Check Supabase docs: https://supabase.com/docs
