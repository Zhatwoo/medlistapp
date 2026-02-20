/// Platform-specific AuthService: web stub (no Firebase) vs mobile impl (Firebase Auth).
export 'authservice_web.dart' if (dart.library.io) 'authservice_impl.dart';
