export 'checkout_redirect_stub.dart'
    if (dart.library.io) 'checkout_redirect_mobile.dart'
    if (dart.library.html) 'checkout_redirect_web.dart';
