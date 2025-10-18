import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:automl/firebase_options.dart';

const String __app_id = 'automl';

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
    // 1. Create the user in Firebase Authentication
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      // 2. Create a corresponding document in the 'users' collection
      await db.collection('users').doc(user.uid).set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': '',
      });
    }

    return null; // Success
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

Stream<User?> get authStateChanges => auth.authStateChanges();