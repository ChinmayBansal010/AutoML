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
    await auth.createUserWithEmailAndPassword(email: email, password: password);
    return null;
  } on FirebaseAuthException catch (e) {
    return e.message;
  } catch (e) {
    return 'An unknown error occurred.';
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