# Cloud Sync Integration Guide

## Overview
Your app now supports cloud sync with Supabase. User data will be:
- **Downloaded to local DB** when logging in on a new device
- **Synced to cloud** when creating/updating records (if user is logged in)

## What's Been Implemented

### 1. Database Migration
File: `supabase/migrations/20260415_create_user_data_tables.sql`
- Creates `customers`, `measurements`, `orders`, `payments` tables in Supabase
- Includes Row Level Security (RLS) policies - users can only see their own data
- Run this migration in your Supabase dashboard

### 2. Cloud Sync Services
- **CloudSyncService**: Fetches/saves data from Supabase
- **DataSyncService**: Syncs cloud data to local SQLite on login
- **AuthProvider**: Automatically fetches cloud data when user logs in

### 3. Available Getters in AuthProvider
```dart
authProvider.currentUserId  // User's ID (null if not logged in)
authProvider.cloudSync      // Access to cloud sync service
authProvider.isAuthenticated // Check if user is logged in
```

## How to Save Data to Cloud

### Option 1: Manual Cloud Save (Simple)
In your UI component (e.g., customer creation screen):

```dart
// Save to local database
final customer = await customerRepository.createCustomer(newCustomer);

// Also save to cloud if user is logged in
final authProvider = Provider.of<AuthProvider>(context, listen: false);
if (authProvider.isAuthenticated) {
  await authProvider.cloudSync.saveCustomerToCloud(
    customer,
    authProvider.currentUserId!,
  );
}
```

### Option 2: Use CustomerSyncService (Recommended)
This wrapper handles both local and cloud saves automatically:

```dart
// In your repository or provider:
final cloudSync = Provider.of<AuthProvider>(context, listen: false).cloudSync;
final customerSync = CustomerSyncService(
  localRepo: customerRepository,
  cloudSync: cloudSync,
  userId: authProvider.currentUserId,
);

// Now use it instead of customerRepository
final customer = await customerSync.createCustomer(newCustomer);
// This will save to both local and cloud automatically!
```

## Data Flow on Login
1. User logs in with OTP
2. `verifyOTP()` is called in AuthProvider
3. Auth state updates → triggers cloud sync
4. `_syncCloudData()` is called
5. All cloud data is fetched and saved to local SQLite
6. User sees their data on the new device

## Important Notes

1. **Local-First Architecture**: Data is always saved locally first for offline support
2. **Cloud Sync is Background**: If cloud sync fails, data is still saved locally
3. **User Filtering**: Supabase RLS policies ensure users only see their own data
4. **UUID vs Integer IDs**: 
   - Cloud uses UUIDs (string IDs)
   - Local SQLite uses INTEGER primary keys
   - This is handled automatically by the sync services

## Testing Cloud Sync

1. Create a customer on Device A while logged in as User1
2. Log out on Device A
3. Log in as User1 on Device B → customer should appear
4. Log out on Device B
5. Log in as User2 on Device B → should see empty list (different user)

## Next Steps

1. Run the migration file on Supabase
2. Update customer creation flow to use cloud sync (see Option 1 or 2 above)
3. Repeat for orders, measurements, and payments
4. Test cloud sync across devices
5. Monitor logs for any sync errors

## Troubleshooting

**"Failed to sync customer: permission denied"**
- Check that RLS policies are enabled
- Verify user is authenticated

**Cloud data not appearing on new device**
- Check browser console for errors
- Verify migration was run
- Check Supabase dashboard for data in tables

**Duplicate data appearing**
- Check `sync_status` column in local database
- May need to manually clear local data and re-login
