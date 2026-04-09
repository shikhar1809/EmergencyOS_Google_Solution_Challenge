import 'dart:js_interop' as js;

void callJsFunction(String fnName, [dynamic args]) {
  try {
    js.window.callMethod(fnName.toJS, args?.toJS);
  } catch (e) {
    print('[WebInterop] Error calling $fnName: $e');
  }
}

bool isFirebaseUIReady() {
  try {
    final result = js.window.callMethod('isFirebaseUIReady'.toJS);
    return result == true;
  } catch (e) {
    return false;
  }
}
