-- Optional admin policies for the GearShare admin panel.
-- Run this in Supabase SQL Editor after creating a Supabase Auth user:
-- email: admin@gmail.com
-- password: admin123

CREATE OR REPLACE FUNCTION public.is_gearshare_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.jwt() ->> 'email' = 'admin@gmail.com';
END;
$$ LANGUAGE plpgsql STABLE;

DROP POLICY IF EXISTS "Admin can manage users" ON public.users;
CREATE POLICY "Admin can manage users"
  ON public.users
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage equipment" ON public.equipment;
CREATE POLICY "Admin can manage equipment"
  ON public.equipment
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage public equipment" ON public.public_equipment;
CREATE POLICY "Admin can manage public equipment"
  ON public.public_equipment
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage equipment images" ON public.equipment_images;
CREATE POLICY "Admin can manage equipment images"
  ON public.equipment_images
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage rentals" ON public.rentals;
CREATE POLICY "Admin can manage rentals"
  ON public.rentals
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage rental payments" ON public.rental_payments;
CREATE POLICY "Admin can manage rental payments"
  ON public.rental_payments
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage rental activity logs" ON public.rental_activity_logs;
CREATE POLICY "Admin can manage rental activity logs"
  ON public.rental_activity_logs
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage chats" ON public.chats;
CREATE POLICY "Admin can manage chats"
  ON public.chats
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());

DROP POLICY IF EXISTS "Admin can manage messages" ON public.messages;
CREATE POLICY "Admin can manage messages"
  ON public.messages
  FOR ALL
  USING (public.is_gearshare_admin())
  WITH CHECK (public.is_gearshare_admin());
