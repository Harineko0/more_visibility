import 'sub/internal.dart';

final hitsProtected =
    subProtected; // expect lint: @mprotected cannot escape dir
final hitsDefault = subDefault; // expect lint: @mdefault cannot escape dir
