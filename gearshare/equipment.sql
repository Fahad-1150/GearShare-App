-- Equipment Management Tables for GearShare

-- Enum for equipment status
CREATE TYPE equipment_status AS ENUM ('available', 'unavailable', 'available_from');

-- Equipment table
CREATE TABLE IF NOT EXISTS equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  per_day_price DECIMAL(10, 2) NOT NULL,
  discount_percentage INTEGER DEFAULT 0,
  discount_min_days INTEGER DEFAULT 7,
  status equipment_status DEFAULT 'available',
  available_from DATE,
  image_url TEXT,
  location_name VARCHAR(255),
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  pickup_address TEXT,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(owner_id, id)
);

-- Public equipment index for main feed
CREATE TABLE IF NOT EXISTS public_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL UNIQUE REFERENCES equipment(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_order INTEGER,
  featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Equipment images table (for multiple images per equipment)
CREATE TABLE IF NOT EXISTS equipment_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_equipment_owner_id ON equipment(owner_id);
CREATE INDEX idx_equipment_is_public ON equipment(is_public);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_public_equipment_featured ON public_equipment(featured);
CREATE INDEX idx_equipment_images_equipment_id ON equipment_images(equipment_id);

-- Enable Row Level Security
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_images ENABLE ROW LEVEL SECURITY;

-- RLS Policies for equipment
CREATE POLICY "Users can view their own equipment" ON equipment
  FOR SELECT USING (owner_id = auth.uid());

CREATE POLICY "Users can insert their own equipment" ON equipment
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own equipment" ON equipment
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Users can delete their own equipment" ON equipment
  FOR DELETE USING (owner_id = auth.uid());

CREATE POLICY "Anyone can view public equipment" ON equipment
  FOR SELECT USING (is_public = true);

-- RLS Policies for public_equipment
CREATE POLICY "Users can view all public equipment" ON public_equipment
  FOR SELECT USING (true);

CREATE POLICY "Users can insert public equipment for their own items" ON public_equipment
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own public equipment" ON public_equipment
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Users can delete their own public equipment" ON public_equipment
  FOR DELETE USING (owner_id = auth.uid());

-- RLS Policies for equipment_images
CREATE POLICY "Anyone can view equipment images" ON equipment_images
  FOR SELECT USING (true);

CREATE POLICY "Users can insert images for their equipment" ON equipment_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM equipment 
      WHERE equipment.id = equipment_images.equipment_id 
      AND equipment.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update images for their equipment" ON equipment_images
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM equipment 
      WHERE equipment.id = equipment_images.equipment_id 
      AND equipment.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete images for their equipment" ON equipment_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM equipment 
      WHERE equipment.id = equipment_images.equipment_id 
      AND equipment.owner_id = auth.uid()
    )
  );

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_equipment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER equipment_update_timestamp
BEFORE UPDATE ON equipment
FOR EACH ROW
EXECUTE FUNCTION update_equipment_timestamp();

-- Sample data (optional - for testing)
-- INSERT INTO equipment (owner_id, name, description, per_day_price, status, location_name)
-- VALUES (
--   '00000000-0000-0000-0000-000000000000',
--   'Mountain Bike',
--   'High-quality mountain bike for trails',
--   25.00,
--   'available',
--   'Downtown Park'
-- );
