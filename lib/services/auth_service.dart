import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resq_flutter/services/notification_service.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String> _generateUniqueId() async {
    final random = Random();
    String newId = '';
    bool isUnique = false;

    while (!isUnique) {
      int randomNumber = random.nextInt(99999999);
      newId = 'RESQ-${randomNumber.toString().padLeft(8, '0')}';


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

  Future<String?> signUp({
    required String email,
    required String password,
    required String role,
    required String username,
    required String phoneNumber,
    String? responderType,
    Map<String, String>? documents,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

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
          'verificationStatus': 'pending', // Admins must verify everyone
        };

        if (role == 'emergency_responder') {
          if (responderType != null) userData['responderType'] = responderType;
        }

        if (documents != null) userData['documents'] = documents;


        await _firestore.collection('users').doc(user.uid).set(userData);


        await NotificationService().updateToken();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'The account already exists for that email.';
      if (e.code == 'weak-password') return 'The password provided is too weak.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await NotificationService().updateToken();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Wrong password provided.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '773245302476-93j4rkud9gq2lfi19qabgnso1vsn2kat.apps.googleusercontent.com',
      ).signIn();
      
      if (googleUser == null) return {'error': 'Google sign in cancelled.', 'isNewUser': false};


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          return {'error': null, 'isNewUser': true, 'user': user};
        }
        await NotificationService().updateToken();
        return {'error': null, 'isNewUser': false, 'user': user};
      }
      return {'error': 'Unknown error occurred.', 'isNewUser': false};
    } catch (e) {
      return {'error': e.toString(), 'isNewUser': false};
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
    }
    return null;
  }

  Future<String?> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update(data);
        return null;
      }
      return 'User not logged in';
    } catch (e) {
      return e.toString();
    }
  }
}

