import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

/// FirebaseService handles all Firebase operations
/// All methods are safe - they fail gracefully if Firebase is unavailable
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._init();
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  bool _isInitialized = false;
  bool _isAvailable = false;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._init();

  /// Initialize Firebase - call this once in main()
  Future<void> initialize() async {
    try {
      debugPrint('🔥 Initializing Firebase...');
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      _isAvailable = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
      _isInitialized = true;
      _isAvailable = false;
      // App continues to work without Firebase
    }
  }

  /// Check if Firebase is available
  bool get isAvailable => _isAvailable;

  /// Get current user ID (for anonymous or signed-in user)
  Future<String?> getUserId() async {
    if (!_isAvailable) return null;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        return user.uid;
      }

      // Sign in anonymously if not already
      final result = await _auth.signInAnonymously();
      return result.user?.uid;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  /// ✅ Save customers to Firestore
  Future<bool> saveCustomers(List<Customer> customers) async {
    if (!_isAvailable) {
      debugPrint('Firebase not available, skipping customer backup');
      return false;
    }

    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint('No user ID available');
        return false;
      }

      debugPrint('💾 Saving ${customers.length} customers to Firestore...');

      final batch = _firestore.batch();

      for (final customer in customers) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('customers')
            .doc('${customer.id}');

        batch.set(docRef, customer.toMap());
      }

      await batch.commit();
      debugPrint('✅ Customers saved to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving customers: $e');
      return false;
    }
  }

  /// ✅ Get customers from Firestore
  Future<List<Customer>> getCustomers() async {
    if (!_isAvailable) {
      debugPrint('Firebase not available');
      return [];
    }

    try {
      final userId = await getUserId();
      if (userId == null) return [];

      debugPrint('📥 Fetching customers from Firestore...');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .get();

      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data()))
          .toList();

      debugPrint('✅ Retrieved ${customers.length} customers from Firestore');
      return customers;
    } catch (e) {
      debugPrint('❌ Error getting customers: $e');
      return [];
    }
  }

  /// ✅ Save orders to Firestore
  Future<bool> saveOrders(List<Order> orders) async {
    if (!_isAvailable) {
      debugPrint('Firebase not available, skipping order backup');
      return false;
    }

    try {
      final userId = await getUserId();
      if (userId == null) return false;

      debugPrint('💾 Saving ${orders.length} orders to Firestore...');

      final batch = _firestore.batch();

      for (final order in orders) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc('${order.id}');

        batch.set(docRef, order.toMap());
      }

      await batch.commit();
      debugPrint('✅ Orders saved to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving orders: $e');
      return false;
    }
  }

  /// ✅ Get orders from Firestore
  Future<List<Order>> getOrders() async {
    if (!_isAvailable) {
      debugPrint('Firebase not available');
      return [];
    }

    try {
      final userId = await getUserId();
      if (userId == null) return [];

      debugPrint('📥 Fetching orders from Firestore...');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .get();

      final orders = snapshot.docs
          .map((doc) => Order.fromMap(doc.data()))
          .toList();

      debugPrint('✅ Retrieved ${orders.length} orders from Firestore');
      return orders;
    } catch (e) {
      debugPrint('❌ Error getting orders: $e');
      return [];
    }
  }

  /// ✅ Save backup metadata (timestamp, version, etc)
  Future<bool> saveBackupMetadata({
    required int customerCount,
    required int orderCount,
  }) async {
    if (!_isAvailable) return false;

    try {
      final userId = await getUserId();
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc('latest_metadata')
          .set({
        'timestamp': DateTime.now().toIso8601String(),
        'customerCount': customerCount,
        'orderCount': orderCount,
        'appVersion': '1.0.0', // Update as needed
      });

      debugPrint('✅ Backup metadata saved');
      return true;
    } catch (e) {
      debugPrint('Error saving backup metadata: $e');
      return false;
    }
  }

  /// ✅ Get last backup info from Firestore
  Future<Map<String, dynamic>?> getLastBackupInfo() async {
    if (!_isAvailable) return null;

    try {
      final userId = await getUserId();
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc('latest_metadata')
          .get();

      return doc.data();
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      return null;
    }
  }

  /// ✅ Delete all data from Firestore (for testing/cleanup)
  Future<bool> deleteAllData() async {
    if (!_isAvailable) return false;

    try {
      final userId = await getUserId();
      if (userId == null) return false;

      debugPrint('🗑️ Deleting all Firestore data for user...');

      await _firestore.collection('users').doc(userId).delete();

      debugPrint('✅ All Firestore data deleted');
      return true;
    } catch (e) {
      debugPrint('Error deleting data: $e');
      return false;
    }
  }

  /// ✅ Test Firebase connectivity
  Future<bool> testConnection() async {
    if (!_isAvailable) {
      debugPrint('Firebase not available');
      return false;
    }

    try {
      debugPrint('🔍 Testing Firebase connection...');

      // Try a simple read
      await _firestore
          .collection('test')
          .doc('test')
          .get(GetOptions(source: Source.server));

      debugPrint('✅ Firebase connection OK');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase connection failed: $e');
      return false;
    }
  }
}