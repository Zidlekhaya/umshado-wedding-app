# Packages Database Setup

The packages functionality requires database tables that don't exist yet. Follow these steps to set up the packages system:

## Step 1: Run the SQL Migration

1. Go to your Supabase dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `create_packages_tables.sql`
4. Click "Run" to execute the migration

## Step 2: Verify Tables Created

After running the migration, you should see these new tables in your database:
- `packages` - Main packages table
- `package_items` - Package items/inclusions
- `package_addons` - Package add-ons
- `package_images` - Package images

## Step 3: Test the Functionality

1. Go to the vendor packages page
2. Click "Add New Package"
3. Fill in the package details
4. Click "Create Package"
5. The package should appear in your packages list

## What This Migration Creates

### Tables:
- **packages**: Main package information (name, description, pricing, etc.)
- **package_items**: Items included in packages
- **package_addons**: Optional add-ons for packages
- **package_images**: Images associated with packages

### Security:
- Row Level Security (RLS) enabled on all tables
- Policies allow vendors to manage their own packages
- Public read access for couples to view packages

### Features:
- Automatic timestamps (created_at, updated_at)
- Foreign key relationships with vendor_profiles
- Cascade deletes (deleting a package removes all related items/addons/images)
- Performance indexes for fast queries

## Troubleshooting

If you encounter any errors:
1. Make sure you're running the SQL in the correct Supabase project
2. Check that the `vendor_profiles` table exists (it should from previous setup)
3. Verify you have the necessary permissions in Supabase

The packages system will work once these tables are created!








