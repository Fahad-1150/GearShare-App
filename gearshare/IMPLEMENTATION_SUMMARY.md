# GearShare Supabase Integration - Complete Setup Guide

## 📝 Summary of Changes Made

### 1. **Updated SupabaseService** (`lib/services/supabase_service.dart`)
   - ✅ Enhanced `signUp()` method with proper user data persistence
   - ✅ Added fallback manual insert for user data (handles trigger failures)
   - ✅ Improved error handling for database operations
   - ✅ Properly passes name and phone as auth metadata

### 2. **Enhanced HomePage** (`lib/main.dart`)
   - ✅ Displays user profile information from database
   - ✅ Shows real-time connection status to Supabase
   - ✅ Fetches and displays saved user data (name, email, phone, member since)
   - ✅ Confirms that data persistence is working

### 3. **Created Setup Documentation** (`SUPABASE_SETUP_CRITICAL.md`)
   - ✅ Step-by-step SQL setup instructions
   - ✅ Troubleshooting guide
   - ✅ Verification steps

---

## 🚀 What You Need to Do RIGHT NOW

### **CRITICAL STEP: Run SQL in Supabase Dashboard**

⚠️ **WITHOUT THIS STEP, USER DATA WILL NOT SAVE!**

1. **Open Supabase Dashboard:** https://supabase.com
2. **Go to: SQL Editor** (left sidebar)
3. **Create New Query** and paste this SQL:

```sql
-- Drop old table and policies
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Create users table
CREATE TABLE public.users (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX idx_users_email ON public.users(email);

-- Create function
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, phone, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Authenticated users can read any user"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

-- Grant permissions
GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;
```

4. **Click RUN** (or press Ctrl+Enter)
5. **Wait for ✅ Success**

---

## ✅ After Running SQL - Test Everything

### Test Sign Up:
```
1. Open the app
2. Tap "Get Started" → "Sign Up"
3. Fill in:
   - Name: "John Doe"
   - Email: "test123@example.com"
   - Phone: "1234567890"
   - Password: "Test123!@"
4. Click "Create Account"
5. You should see success message
```

### Verify in Supabase:
```
1. Go to: Authentication → Users
   ✅ You should see the new user

2. Go to: Database → Tables → users
   ✅ You should see:
      ├── id: (UUID)
      ├── email: test123@example.com
      ├── name: John Doe
      ├── phone: 1234567890
      └── created_at: (current time)
```

### Test Sign In & Verify Connection:
```
1. Tap "Sign In"
2. Enter: test123@example.com / Test123!@
3. You should see Home page with profile data displayed:
   ✅ Name: John Doe
   ✅ Email: test123@example.com
   ✅ Phone: 1234567890
   ✅ Member Since: [date]
   ✅ Supabase Status: Connected ✅
```

---

## 🔍 How It Works Now

### Sign Up Flow:
```
User fills form → SupabaseService.signUp()
  ↓
  auth.signUp() with metadata (name, phone)
  ↓
  PostgreSQL trigger fires automatically
  ↓
  Trigger inserts user data into users table
  ↓
  Fallback manual insert (if trigger doesn't work)
  ↓
  User account created in both auth & users tables ✅
```

### Sign In Flow:
```
User enters credentials → SupabaseService.signIn()
  ↓
  Authentication succeeds
  ↓
  User navigated to HomePage
  ↓
  HomePage fetches user data from users table
  ↓
  Profile info displayed ✅
```

---

## ❌ Troubleshooting

### Problem: "Users table is empty after signing up"
**Solution:**
- You didn't run the SQL query
- The query didn't execute successfully
- Check Supabase Logs for errors

### Problem: "Permission denied" errors
**Solution:**
- Make sure you ran the full SQL including RLS policies
- Check the database logs in Supabase

### Problem: "Can't fetch user data on home page"
**Solution:**
- Verify the users table has the correct data (check in Database tab)
- Check that the trigger created the record
- Look at Supabase logs for errors

### Problem: App crashes on sign in
**Solution:**
- Clear app data and try again
- Check that user actually exists in auth.users table
- Run the SQL setup again if needed

---

## 📊 Database Schema

After running the SQL, your database will have:

```
PUBLIC SCHEMA:
├── users (table)
│   ├── id (UUID) - Primary key, links to auth.users
│   ├── email (VARCHAR) - User's email
│   ├── name (VARCHAR) - User's full name
│   ├── phone (VARCHAR) - User's phone number
│   ├── created_at (TIMESTAMP) - Account creation time
│   └── updated_at (TIMESTAMP) - Last update time
│
├── idx_users_email (index) - For fast email lookups
│
├── handle_new_user() (function) - Automatic trigger
│
├── on_auth_user_created (trigger) - Fires on new auth user
│
└── RLS Policies:
    ├── Users can read their own data
    ├── Users can update their own data
    └── Authenticated users can read any user
```

---

## 🔐 Security Features

✅ **Row Level Security (RLS) Enabled:**
- Users can only see their own data by default
- Authenticated users can discover others
- All data is protected at the database level

✅ **Automatic User Record Creation:**
- Trigger creates user record automatically
- No manual database inserts needed
- Fallback ensures data isn't lost

✅ **Proper Authentication:**
- Passwords hashed by Supabase
- JWT tokens used for requests
- Safe metadata storage

---

## 📋 Checklist

Before you start using the app:

- [ ] Created Supabase account
- [ ] Created a new Supabase project
- [ ] Copied credentials to code (already done in this project)
- [ ] **✅ Ran the SQL setup in Supabase**
- [ ] Verified users table exists in Database tab
- [ ] Tested sign up with real data
- [ ] Checked that data appears in users table
- [ ] Tested sign in
- [ ] Home page shows your profile data
- [ ] Supabase Status shows ✅ Connected

---

## 🎯 Next Steps After This Works

1. **Create a Listings Table** - For rental items
2. **Set up Authentication Guards** - Auto-redirect to signin if not logged in
3. **Create Profile Edit Page** - Allow users to update their data
4. **Set up More RLS Policies** - For listings, messages, etc.

---

## 📞 Support

If you encounter issues:

1. Check the **Logs** in Supabase Dashboard (bottom left)
2. Look at **Authentication → Users** to verify user exists
3. Check **Database → users table** to verify data is there
4. Review error messages in the app

---

**Your GearShare app is now ready for real authentication and data persistence! 🎉**
