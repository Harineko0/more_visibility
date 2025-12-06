import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

enum VisibilityKind { protected, moduleDefault }

String? _annotationName(Element element) {
  if (element is ConstructorElement) {
    return element.enclosingElement.name;
  }
  return element.displayName;
}

VisibilityKind? visibilityFromAnnotations(
  Iterable<ElementAnnotation> metadata,
) {
  for (final annotation in metadata) {
    final element = annotation.element;
    final name = element != null ? _annotationName(element) : null;
    final valueType = annotation
        .computeConstantValue()
        ?.type
        ?.element
        ?.displayName;
    final source = annotation.toSource();
    final matchedName =
        name ??
        valueType ??
        (source.contains('mprotected')
            ? 'mprotected'
            : (source.contains('mdefault') ? 'mdefault' : null));

    if (!_isMoreVisibilityAnnotationName(matchedName)) continue;

    if (matchedName == 'mdefault' || matchedName == 'MDefault') {
      return VisibilityKind.moduleDefault;
    }
    if (matchedName == 'mprotected' || matchedName == 'MProtected') {
      return VisibilityKind.protected;
    }
  }
  return null;
}

bool _isMoreVisibilityAnnotationName(String? name) {
  if (name == null) return false;
  return name == 'mprotected' ||
      name == 'MProtected' ||
      name == 'mdefault' ||
      name == 'MDefault';
}

VisibilityKind? visibilityFromNodeMetadata(NodeList<Annotation> metadata) {
  return visibilityFromAnnotations(
    metadata
        .map((annotation) => annotation.elementAnnotation)
        .whereType<ElementAnnotation>(),
  );
}
