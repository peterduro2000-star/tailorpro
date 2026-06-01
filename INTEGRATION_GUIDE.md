# CustomerSyncService Integration Guide

## Overview
`CustomerSyncService` automatically saves data to both local SQLite and Supabase cloud. When a customer is created/updated and the user is logged in, it syncs to the cloud.

## ✅ Already Updated
- **AddCustomer screen** - Both create and update operations now use cloud sync

## How It Works
```dart
// Creates customer in both local and cloud (if logged in)
final createdCustomer = await _customerSyncService.createCustomer(newCustomer);

// Updates customer in both local and cloud
await _customerSyncService.updateCustomer(updatedCustomer);

// Read operations work normally
final customers = await _customerSyncService.getAllCustomers();
```

---

## Step 1: Initialize CustomerSyncService

In any screen/provider where you need it:

```dart
import '../../services/customer_sync_service.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  late CustomerSyncService _customerSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _customerSyncService = CustomerSyncService(
        localRepo: _customerRepository,
        cloudSync: authProvider.cloudSync,
        userId: authProvider.currentUserId,
      );
    });
  }
```

---

## Step 2: Replace Repository Calls

### Creating a Customer
```dart
// ❌ OLD - Only saves locally
// final customer = await _customerRepository.createCustomer(newCustomer);

// ✅ NEW - Saves to both local and cloud
final customer = await _customerSyncService.createCustomer(newCustomer);
```

### Updating a Customer
```dart
// ❌ OLD - Only saves locally
// await _customerRepository.updateCustomer(updatedCustomer);

// ✅ NEW - Saves to both local and cloud
await _customerSyncService.updateCustomer(updatedCustomer);
```

### Deleting a Customer
```dart
// ✅ Works the same (already local only for now)
await _customerSyncService.deleteCustomer(customerId);
```

### Reading Data
```dart
// ✅ All read operations work the same
final customers = await _customerSyncService.getAllCustomers();
final customer = await _customerSyncService.getCustomerById(id);
final results = await _customerSyncService.searchCustomers(query);
```

---

## Example: Customer Selection Widget

Before:
```dart
class CustomerSelectionWidget extends StatefulWidget {
  @override
  State<CustomerSelectionWidget> createState() => _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final CustomerRepository _customerRepository = CustomerRepository();

  Future<void> _addNewCustomer() async {
    final result = await Navigator.of(context, rootNavigator: true)
        .pushNamed('/add-customer');
    if (result == true) {
      await _loadCustomers();
    }
  }
}
```

After:
```dart
class CustomerSelectionWidget extends StatefulWidget {
  @override
  State<CustomerSelectionWidget> createState() => _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final CustomerRepository _customerRepository = CustomerRepository();
  late CustomerSyncService _customerSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _customerSyncService = CustomerSyncService(
        localRepo: _customerRepository,
        cloudSync: authProvider.cloudSync,
        userId: authProvider.currentUserId,
      );
    });
  }

  Future<void> _addNewCustomer() async {
    // The AddCustomer screen already uses sync,
    // so no changes needed here - it still just reloads the list
    final result = await Navigator.of(context, rootNavigator: true)
        .pushNamed('/add-customer');
    if (result == true) {
      await _loadCustomers();
    }
  }
}
```

---

## Data Flow With Cloud Sync

### When User is Logged In ✅
```
Device A: User creates customer
    ↓
CustomerSyncService.createCustomer()
    ↓
    ├─ Save to Local SQLite
    ├─ Save to Supabase Cloud ← User ID attached
    ↓
Device B: User logs in
    ↓
AuthProvider._syncCloudData()
    ↓
    ├─ Fetch from cloud
    ├─ Save to local SQLite
    ↓
Customer appears on Device B
```

### When User is Not Logged In
```
If userId is null, sync service skips cloud save
Data is saved locally only
Will sync to cloud when user logs in
```

---

## Benefits of Option 2

✅ **Automatic Cloud Sync** - No extra code needed in each screen
✅ **Consistent Data** - Easy to see data across devices  
✅ **Offline Support** - Works locally even without internet
✅ **Clean Code** - Replace repo calls with sync calls
✅ **Error Handling** - Cloud sync failures don't block local saves

---

## Next Steps

1. **Optional**: Update [CustomerList](../../presentation/customer_list/customer_list.dart) to use CustomerSyncService
2. **Optional**: Apply the same pattern to Orders, Measurements, Payments (copy the CustomerSyncService as OrderSyncService, etc.)
3. **Test**: Create customer on Device A → Log in on Device B → See customer appear

---

## Troubleshooting

**Customer not syncing to cloud?**
- Check that user is logged in: `authProvider.isAuthenticated`
- Check logs for "Failed to sync customer" messages
- Verify Supabase table exists (run migration)

**Seeing old customer data after login?**
- This is expected - `_syncCloudData` runs in background
- Wait a moment and refresh screen

**Duplicate customers?**
- Clear local database and re-login
- Or check `sync_status` column for orphaned records
