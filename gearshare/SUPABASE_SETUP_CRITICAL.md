# 🔥 CRITICAL: Supabase Setup to Fix User Data Saving Issue

## IMPORTANT: You MUST Complete These Steps or User Data Won't Save!

---

## Step 1: Run SQL Query in Supabase Dashboard

1. **Go to your Supabase Dashboard** → https://supabase.com
2. **Navigate to SQL Editor** (Left sidebar)
3. **Click "New Query"**
4. **Copy and paste the entire SQL code below:**

```sql
-- ⚠️ RUN THIS SQL IN SUPABASE SQL EDITOR TO FIX THE SIGNUP ISSUE

-- Step 1: Drop old table and policies (if they exist)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Step 2: Create the users table
CREATE TABLE public.users (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create index on email
CREATE INDEX idx_users_email ON public.users(email);

-- Step 4: Create a function to handle new user creation
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

-- Step 5: Create trigger to automatically create user record
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 6: Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies
CREATE POLICY "Users can read their own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Step 8: Users can read their own profile for initial load
CREATE POLICY "Authenticated users can read any user (for discovery)"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

-- Optional: Grant permissions
GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;
```

5. **Click the blue "RUN" button** (or press Ctrl+Enter)
6. **Wait for the query to complete successfully** - you should see ✅ Success message

---

## Step 2: Enable Email Authentication (if not already enabled)

1. Go to **Authentication** (left sidebar) → **Providers**
2. Make sure **Email** provider is enabled (checkmark)
3. Click **Save**

---

## Step 3: Test Your Setup

### Test Sign Up:
1. Run your Flutter app
2. Go to **Sign Up** page
3. Fill in details:
   - Name: `John Doe`
   - Email: `test@example.com`
   - Phone: `1234567890`
   - Password: `Test123!`
4. Click **Create Account**

### Verify in Supabase:
1. Go to **Authentication** → **Users** - You should see your new user ✅
2. Go to **Database** → **Tables** → **users** - You should see the user record with all data ✅

If the user appears in the users table with name and phone, **everything is working!**

---

## What Was Fixed in the Code

### supabase_service.dart Changes:
- ✅ Properly passes name and phone as metadata to auth.signUp()
- ✅ Manually inserts user data as fallback (if trigger doesn't work)
- ✅ Better error handling with try-catch for the insert
- ✅ Handles duplicate insert gracefully

### This means:
- When users sign up, their data is saved to BOTH:
  1. **auth.users** table (Supabase auth system)
  2. **users** table (your data table)
- When users sign in, they can access the stored profile data

---

## Troubleshooting

### ❌ Users table is empty after sign up?
- ✅ You didn't run the SQL query above
- ✅ The SQL query wasn't executed successfully
- **Fix:** Go back to Step 1 and run the SQL again

### ❌ Getting "permission denied" errors?
- ✅ RLS policies might be blocking the insert
- **Fix:** Make sure you ran the entire SQL including RLS policies

### ❌ Getting "auth_users_id_fkey" error?
- ✅ The trigger might be trying to insert before user is created
- **Fix:** This is handled by the SECURITY DEFINER in the trigger - it should work

### ❌ Still not working?
1. Check the **Logs** in Supabase Dashboard (bottom left)
2. Look for any error messages
3. Share the error message for debugging

---

## Database Schema (After Running SQL)

```
users table:
├── id (UUID) ← references auth.users.id
├── email (VARCHAR)
├── name (VARCHAR)
├── phone (VARCHAR)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
└── idx_users_email on email column

RLS Policies:
├── Users can read their own data
├── Users can update their own data
└── Authenticated users can read any user
```

---

## Next Steps After This Works

Once user sign up/sign in is working:
1. ✅ View user profile from auth system
2. ✅ Update user details in users table
3. ✅ Create listings, messages, etc.
4. ✅ Set up more complex queries

---

**Questions?** Check the logs in Supabase Dashboard or review the SQL errors.
