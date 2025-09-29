-- Create vendor_inquiries table
CREATE TABLE IF NOT EXISTS vendor_inquiries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  customer_phone TEXT,
  service_type TEXT NOT NULL,
  event_date DATE,
  budget_range TEXT,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'quoted', 'booked', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE vendor_inquiries ENABLE ROW LEVEL SECURITY;

-- Create policies for vendor_inquiries
CREATE POLICY "Vendors can view their own inquiries" ON vendor_inquiries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM vendor_profiles 
      WHERE vendor_profiles.id = vendor_inquiries.vendor_id 
      AND vendor_profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can update their own inquiries" ON vendor_inquiries
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM vendor_profiles 
      WHERE vendor_profiles.id = vendor_inquiries.vendor_id 
      AND vendor_profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can create inquiries" ON vendor_inquiries
  FOR INSERT WITH CHECK (true);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vendor_inquiries_vendor_id ON vendor_inquiries(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_inquiries_status ON vendor_inquiries(status);
CREATE INDEX IF NOT EXISTS idx_vendor_inquiries_created_at ON vendor_inquiries(created_at);

-- Add inquiry_count column to vendor_profiles if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'inquiry_count') THEN
    ALTER TABLE vendor_profiles ADD COLUMN inquiry_count INTEGER DEFAULT 0;
  END IF;
END $$;








