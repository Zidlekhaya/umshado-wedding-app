# Environment Setup Instructions

## Step 1: Create .env file

Create a `.env` file in the root directory (C:\Users\Mthabisi\umshado) with your Supabase credentials:

```bash
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url_here
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

## Step 2: Get your Supabase credentials

1. Go to [supabase.com](https://supabase.com) and sign in
2. Select your project (or create a new one)
3. Go to Settings > API
4. Copy:
   - Project URL (e.g., `https://your-project.supabase.co`)
   - anon/public key (the long JWT token)

## Step 3: Replace the placeholders

Replace `your_supabase_url_here` and `your_supabase_anon_key_here` with your actual values.

Example:
```bash
EXPO_PUBLIC_SUPABASE_URL=https://abcdefghijk.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIs...
```

## Step 4: Test the connection

Once you've created the .env file, run:
```bash
npm start
```

You should see "Supabase: Initializing client with URL: Found" in the console.

## Next Steps

After setting up the environment variables, we'll proceed with:
1. Running database migrations
2. Testing all features
3. Fixing any remaining issues

**⚠️ Important**: Never commit your .env file to git - it's already in .gitignore

