-- Quick fix for packages - run this in Supabase SQL Editor

-- Create packages table
CREATE TABLE IF NOT EXISTS packages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  package_name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  short_description TEXT,
  long_description TEXT,
  price_type VARCHAR(20) NOT NULL CHECK (price_type IN ('fixed', 'range', 'hourly', 'per_person')),
  price_min DECIMAL(10,2),
  price_max DECIMAL(10,2),
  currency VARCHAR(3) DEFAULT 'ZAR',
  duration_hours DECIMAL(5,2),
  has_availability BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create package_items table
CREATE TABLE IF NOT EXISTS package_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  item_name VARCHAR(255) NOT NULL,
  item_description TEXT,
  quantity INTEGER DEFAULT 1,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create package_addons table
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

-- Create package_images table
CREATE TABLE IF NOT EXISTS package_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  alt_text VARCHAR(255),
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_images ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies
CREATE POLICY "Packages are viewable by everyone" ON packages FOR SELECT USING (true);
CREATE POLICY "Vendors can manage their own packages" ON packages FOR ALL USING (
  vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
);

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








