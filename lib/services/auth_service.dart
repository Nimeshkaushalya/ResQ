import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Generate Unique ID
  Future<String> _generateUniqueId() async {
    final random = Random();
    String newId = '';
    bool isUnique = false;

    while (!isUnique) {
      // Generate 8 random digits
      int randomNumber = random.nextInt(99999999);
      newId = 'RESQ-${randomNumber.toString().padLeft(8, '0')}';

      // Check if it exists in Firestore
      final query = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: newId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        isUnique = true;
      }
    }

    return newId;
  }

  // Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String role, // 'user' or 'emergency_responder'
    required String username,
    required String phoneNumber,
    String? responderType, // NEW
    Map<String, String>? documents, // NEW
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Save additional user info to Firestore
      if (user != null) {
        String uniqueId = await _generateUniqueId();

        Map<String, dynamic> userData = {
          'uid': user.uid,
          'uniqueId': uniqueId,
          'email': email,
          'role': role,
          'username': username,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (role == 'emergency_responder') {
          if (responderType != null) {
            userData['responderType'] = responderType;
          }
        }

        if (documents != null) {
          userData['documents'] = documents;
        }
        userData['verificationStatus'] = 'pending';
        userData['verificationNote'] = '';

        await _firestore.collection('users').doc(user.uid).set(userData);
      }
      return null; // No error
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      } else if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Stream of user data from Firestore
  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

  // Sign In
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // No error
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-credential') {
        return 'Invalid credentials.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Role
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
    }
    return null;
  }
}
