import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:automl/firebase_options.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;
late final FirebaseFirestore db;

Future<void> initializeFirebase() async {
  app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  auth = FirebaseAuth.instanceFor(app: app);
  db = FirebaseFirestore.instanceFor(app: app);
}

Future<String?> signUp(String email, String password) async {
  try {
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await db.collection('users').doc(user.uid).set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': '',
        'dob': null,
        'apiKey': '',
        'isVerified': false,
      });
    }

    return null;
  } on FirebaseAuthException catch (e) {
    return e.message; // Return Firebase Auth specific errors
  } catch (e) {
    return 'An unknown error occurred.'; // Return generic errors
  }
}

Future<String?> signIn(String email, String password) async {
  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    return null;
  } on FirebaseAuthException catch (e) {
    return e.message;
  } catch (e) {
    return 'An unknown error occurred.';
  }
}

Future<void> signOut() async {
  await auth.signOut();
}

Future<String?> updateUserProfile(String userId, {String? displayName, DateTime? dob}) async {
  try {
    Map<String, dynamic> data = {};
    if (displayName != null) {
      data['displayName'] = displayName;
    }
    if (dob != null) {
      data['dob'] = Timestamp.fromDate(dob);
    }

    if (data.isNotEmpty) {
      await db.collection('users').doc(userId).update(data);
    }
    return null;
  } catch (e) {
    return 'An unknown error occurred: ${e.toString()}';
  }
}

Stream<DocumentSnapshot> fetchUserProfileStream(String userId) {
  return db.collection('users').doc(userId).snapshots();
}

Future<String?> updateApiKeyVerification(String userId, bool isVerified) async {
  try {
    await db.collection('users').doc(userId).set({'isVerified': isVerified}, SetOptions(merge: true));
    return null;
  } catch (e) {
    return 'Failed to update API Key verification status: ${e.toString()}';
  }
}

Future<String?> updateApiKey(String userId, String apiKey) async {
  try {
    await db.collection('users').doc(userId).set({'apiKey': apiKey}, SetOptions(merge: true));
    return null;
  } catch (e) {
    return 'Failed to save API Key: ${e.toString()}';
  }
}

// NEW FUNCTION: Retrieve the API Key from the user's profile
Future<String?> getApiKey(String userId) async {
  try {
    final doc = await db.collection('users').doc(userId).get();
    return doc.data()?['apiKey'] as String?;
  } catch (e) {
    return null;
  }
}


Stream<User?> get authStateChanges => auth.authStateChanges();