# ⚡ QUICK START - 3 Steps to Fix User Data Saving

## Step 1️⃣: Open Supabase SQL Editor

1. Go to: **https://supabase.com**
2. Choose your GearShare project
3. Click **SQL Editor** (left sidebar)
4. Click **New Query**

---

## Step 2️⃣: Copy & Paste This SQL

```sql
-- Copy and paste EVERYTHING below and run it

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE public.users (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON public.users(email);

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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

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

GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;
```

---

## Step 3️⃣: Run It!

**Click the blue "RUN" button** or press **Ctrl+Enter**

**Wait for ✅ Success message**

---

## 🎯 That's it! Now Test Your App

### Open the Flutter app and:

1. **Sign Up:**
   - Get Started → Sign Up
   - Enter any name, email, phone, password
   - Click Create Account

2. **Sign In:**
   - Use the email and password you just created
   - You should see your profile information displayed

3. **Verify in Supabase:**
   - Go to Database → users table
   - You should see your new user data there ✅

---

## ❓ What if it doesn't work?

### Step A: Check the Database Table
1. Go to **Database** → **Tables**
2. Click **users**
3. Do you see any data? 
   - **YES:** Data is saving! ✅
   - **NO:** The SQL didn't work properly. Try running it again.

### Step B: Check Authentication  
1. Go to **Authentication** → **Users**
2. Do you see the user you signed up with?
   - **YES:** Auth works, might be a table issue
   - **NO:** Sign up isn't working. Check the app error message.

### Step C: Check Logs
1. Go to **Logs** (bottom left of dashboard)
2. Look for any error messages
3. Read the error and try to fix it

---

## 🚀 You're Done!

Both signup and signin are now:
- ✅ Saving user data in Supabase
- ✅ Retrieving profile information
- ✅ Persisting between app restarts
- ✅ Secure with Row Level Security

Now everything should work! 🎉
