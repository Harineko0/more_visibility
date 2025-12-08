import 'pages/_components/button.dart';

/// This is NOT allowed - different depth (lib/ vs lib/pages/)
void useBar() {
  privateButton(); // ERROR: directory_private
}
