import 'sub/internal.dart';

// expect lint: @mprotected cannot escape dir
final hitsProtected = subProtected;
// expect lint: @mdefault cannot escape dir
final hitsDefault = subDefault;
