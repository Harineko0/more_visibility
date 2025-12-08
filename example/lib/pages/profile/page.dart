import '../_components/button.dart';

/// This is NOT allowed - different depth (lib/pages/profile/ vs lib/pages/)
void Profile() {
  privateButton(); // ERROR: directory_private
}
