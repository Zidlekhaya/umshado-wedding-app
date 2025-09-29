# Umshado - Wedding Planning App 👰🤵

A comprehensive wedding planning app built with React Native and Expo, featuring guest management, budget tracking, task management, and vendor coordination.

## Features

- **Guest Management**: Add, edit, and track wedding guests with RSVP functionality
- **Budget Tracking**: Monitor wedding expenses and budget allocation
- **Task Management**: Organize wedding planning tasks with priorities and deadlines
- **Vendor Management**: Keep track of wedding vendors and their details
- **Timeline Planning**: Plan your wedding timeline with important milestones
- **Real-time Updates**: Sync data across devices with Supabase backend

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Expo CLI
- Supabase account (for backend services)

## Environment Setup

1. Create a `.env` file in the root directory with your Supabase credentials:

   ```bash
   EXPO_PUBLIC_SUPABASE_URL=your_supabase_url_here
   EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

2. Get your Supabase credentials:
   - Go to [supabase.com](https://supabase.com)
   - Create a new project or use an existing one
   - Go to Settings > API
   - Copy the Project URL and anon public key

## Get started

1. Install dependencies

   ```bash
   npm install
   ```

2. Set up your environment variables (see Environment Setup above)

3. Start the app

   ```bash
   npx expo start
   ```

In the output, you'll find options to open the app in a

- [development build](https://docs.expo.dev/develop/development-builds/introduction/)
- [Android emulator](https://docs.expo.dev/workflow/android-studio-emulator/)
- [iOS simulator](https://docs.expo.dev/workflow/ios-simulator/)
- [Expo Go](https://expo.dev/go), a limited sandbox for trying out app development with Expo

You can start developing by editing the files inside the **app** directory. This project uses [file-based routing](https://docs.expo.dev/router/introduction).

## Get a fresh project

When you're ready, run:

```bash
npm run reset-project
```

This command will move the starter code to the **app-example** directory and create a blank **app** directory where you can start developing.

## Learn more

To learn more about developing your project with Expo, look at the following resources:

- [Expo documentation](https://docs.expo.dev/): Learn fundamentals, or go into advanced topics with our [guides](https://docs.expo.dev/guides).
- [Learn Expo tutorial](https://docs.expo.dev/tutorial/introduction/): Follow a step-by-step tutorial where you'll create a project that runs on Android, iOS, and the web.

## Join the community

Join our community of developers creating universal apps.

- [Expo on GitHub](https://github.com/expo/expo): View our open source platform and contribute.
- [Discord community](https://chat.expo.dev): Chat with Expo users and ask questions.
