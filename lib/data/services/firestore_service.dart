import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin typed wrapper around [FirebaseFirestore] providing CRUD helpers
/// used by all repositories for consistent Firestore access.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  // ---------------------------------------------------------------------------
  // Collection helpers
  // ---------------------------------------------------------------------------

  /// Returns a typed document reference.
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Returns a typed collection reference.
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD
  // ---------------------------------------------------------------------------

  /// Fetches a single document by path and converts it using [fromMap].
  Future<T?> getDocument<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final doc = await _firestore.doc(path).get();
    if (doc.exists && doc.data() != null) {
      return fromMap(doc.data()!);
    }
    return null;
  }

  /// Fetches all documents in a collection and converts them using [fromMap].
  Future<List<T>> getCollection<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final snapshot = await _firestore.collection(path).get();
    return snapshot.docs
        .where((doc) => doc.data().isNotEmpty)
        .map((doc) => fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Fetches documents matching a query and converts them using [fromMap].
  Future<List<T>> queryCollection<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap, {
    String? whereField,
    dynamic isEqualTo,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (whereField != null && isEqualTo != null) {
      query = query.where(whereField, isEqualTo: isEqualTo);
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .where((doc) => doc.data().isNotEmpty)
        .map((doc) => fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Sets a document at the given path (creates or overwrites).
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  /// Updates specific fields of an existing document.
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _firestore.doc(path).update(data);
  }

  /// Deletes a document at the given path.
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  /// Adds a document to a collection with an auto-generated ID.
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collectionPath).add(data);
  }

  // ---------------------------------------------------------------------------
  // Stream helpers (for real-time updates)
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of documents in a collection.
  Stream<List<T>> streamCollection<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap, {
    String? orderByField,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().isNotEmpty)
              .map((doc) => fromMap({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  /// Returns a real-time stream of a single document.
  Stream<T?> streamDocument<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    return _firestore.doc(path).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return fromMap(doc.data()!);
      }
      return null;
    });
  }
}
