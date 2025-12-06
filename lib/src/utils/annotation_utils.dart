import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

enum VisibilityKind { protected, moduleDefault }

String? _annotationName(Element element) {
  if (element is ConstructorElement) {
    return element.enclosingElement.name;
  }
  return element.displayName;
}

bool _isMoreVisibilityAnnotation(Element? element) {
  if (element == null) return false;
  final name = _annotationName(element);
  if (name != 'mprotected' &&
      name != 'MProtected' &&
      name != 'mdefault' &&
      name != 'MDefault') {
    return false;
  }
  return true;
}

VisibilityKind? visibilityFromAnnotations(
  Iterable<ElementAnnotation> metadata,
) {
  for (final annotation in metadata) {
    final element = annotation.element;
    if (element == null) continue;
    if (!_isMoreVisibilityAnnotation(element)) continue;
    final name = _annotationName(element);
    if (name == 'mdefault' || name == 'MDefault') {
      return VisibilityKind.moduleDefault;
    }
    if (name == 'mprotected' || name == 'MProtected') {
      return VisibilityKind.protected;
    }
  }
  return null;
}

VisibilityKind? visibilityFromNodeMetadata(NodeList<Annotation> metadata) {
  return visibilityFromAnnotations(
    metadata
        .map((annotation) => annotation.elementAnnotation)
        .whereType<ElementAnnotation>(),
  );
}
