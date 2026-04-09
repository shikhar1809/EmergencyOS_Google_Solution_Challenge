/// Web OAuth client ID used by [GoogleSignIn] on Android/iOS with Firebase Auth.
///
/// In [Firebase Console](https://console.firebase.google.com/) for **emergencyos-101**:
/// **Authentication → Sign-in method → Google** → enable → copy **Web client ID**
/// (Web SDK configuration). After that, `google-services.json` usually also lists a
/// `client_id` with `"client_type": 3` under `oauth_client`.
///
/// Leave empty only if you are not using Google sign-in on native builds yet.
const String kGoogleSignInWebClientId = '';
