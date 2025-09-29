# Vendor Inquiries Setup

## Overview
The vendor inquiries functionality allows customers to send inquiries to vendors about their services. This document explains how to set up and test the inquiries system.

## Database Setup

### 1. Run the SQL Migration
Execute the SQL script in `create_inquiries_table.sql` in your Supabase dashboard:

```sql
-- This will create the vendor_inquiries table with proper RLS policies
-- Run this in your Supabase SQL editor
```

### 2. Table Structure
The `vendor_inquiries` table includes:
- `id`: Unique identifier
- `vendor_id`: References vendor_profiles table
- `customer_name`: Customer's name
- `customer_email`: Customer's email
- `customer_phone`: Customer's phone (optional)
- `service_type`: Type of service inquired about
- `event_date`: Date of the event (optional)
- `budget_range`: Customer's budget range (optional)
- `message`: Inquiry message
- `status`: Inquiry status (new, contacted, quoted, booked, cancelled)
- `created_at`: Timestamp when created
- `updated_at`: Timestamp when last updated

## Testing

### 1. Use the Test Page
Navigate to the test inquiries page (`/test-inquiries`) to:
- Add sample inquiries
- Test the inquiry retrieval functionality

### 2. Test the Messages Page
After adding sample data:
1. Go to the Messages tab in the vendor dashboard
2. Switch to the "Inquiries" tab
3. You should see the sample inquiries with status update buttons

## Features

### Status Management
- **New**: Initial inquiry status
- **Contacted**: Vendor has contacted the customer
- **Quoted**: Vendor has sent a quote
- **Booked**: Customer has booked the service
- **Cancelled**: Inquiry was cancelled

### Error Handling
The system gracefully handles cases where the `vendor_inquiries` table doesn't exist yet:
- Returns empty arrays instead of throwing errors
- Logs informative messages instead of error messages
- Allows the app to function normally

## API Functions

### `getVendorInquiries(vendorId: string)`
Returns all inquiries for a specific vendor, ordered by creation date (newest first).

### `updateInquiryStatus(inquiryId: string, status: string)`
Updates the status of a specific inquiry.

### `addVendorInquiry(inquiry: VendorInquiry)`
Adds a new inquiry (useful for testing).

## Security
- Row Level Security (RLS) is enabled
- Vendors can only see their own inquiries
- Anyone can create inquiries (for customer submissions)
- Vendors can update their own inquiries

## Next Steps
1. Run the SQL migration in Supabase
2. Test with sample data using the test page
3. Integrate inquiry creation into the customer-facing parts of the app
4. Add email notifications for new inquiries








