import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:automl/firebase_options.dart';

const String __app_id = 'automl';
const String __initial_auth_token = '';

late final FirebaseApp app;
late final FirebaseAuth auth;
late final FirebaseFirestore db;

late String currentUserId;

Future<String> initializeFirebase() async {
  try {
    app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    auth = FirebaseAuth.instanceFor(app: app);
    db = FirebaseFirestore.instanceFor(app: app);

    if (__initial_auth_token.isNotEmpty) {
      UserCredential userCredential = await auth.signInWithCustomToken(__initial_auth_token);
      currentUserId = userCredential.user!.uid;
    } else {
      UserCredential userCredential = await auth.signInAnonymously();
      currentUserId = userCredential.user!.uid;
    }
    return "Firebase initialized and authenticated successfully.";

  } on FirebaseException catch (e) {
    if (e.code == 'app-already-initialized') {
      app = Firebase.apps.first;
      auth = FirebaseAuth.instanceFor(app: app);
      db = FirebaseFirestore.instanceFor(app: app);
      currentUserId = auth.currentUser?.uid ?? const Uuid().v4();
      return "Firebase reinitialized (Hot Reload).";
    } else {
      currentUserId = const Uuid().v4();
      return "Firebase initialization error: ${e.code} - ${e.message}";
    }
  } catch (e) {
    currentUserId = const Uuid().v4();
    return "General Firebase error: $e";
  }
}

String getUserCollectionPath(String collectionName) {
  return 'artifacts/$__app_id/users/$currentUserId/$collectionName';
}

String getPublicCollectionPath(String collectionName) {
  return 'artifacts/$__app_id/public/data/$collectionName';
}
