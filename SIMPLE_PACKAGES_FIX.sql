-- Simple packages fix - run this in Supabase SQL Editor

-- First, let's create the missing tables
CREATE TABLE IF NOT EXISTS package_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  item_name VARCHAR(255) NOT NULL,
  item_description TEXT,
  quantity INTEGER DEFAULT 1,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS package_addons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  price_type VARCHAR(20) NOT NULL CHECK (price_type IN ('fixed', 'per_person', 'hourly')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS package_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  alt_text VARCHAR(255),
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for the new tables
ALTER TABLE package_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_images ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for the new tables
CREATE POLICY "Package items are viewable by everyone" ON package_items FOR SELECT USING (true);
CREATE POLICY "Vendors can manage items for their packages" ON package_items FOR ALL USING (
  package_id IN (SELECT id FROM packages WHERE vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid()))
);

CREATE POLICY "Package addons are viewable by everyone" ON package_addons FOR SELECT USING (true);
CREATE POLICY "Vendors can manage addons for their packages" ON package_addons FOR ALL USING (
  package_id IN (SELECT id FROM packages WHERE vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid()))
);

CREATE POLICY "Package images are viewable by everyone" ON package_images FOR SELECT USING (true);
CREATE POLICY "Vendors can manage images for their packages" ON package_images FOR ALL USING (
  package_id IN (SELECT id FROM packages WHERE vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid()))
);








