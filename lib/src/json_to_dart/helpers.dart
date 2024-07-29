import 'dart:convert' as Convert;
import 'dart:math';
import 'package:json_ast/json_ast.dart'
    show Node, ObjectNode, ArrayNode, LiteralNode, PropertyNode;

import 'syntax.dart';

const Map<String, bool> PRIMITIVE_TYPES = <String, bool>{
  'int': true,
  'double': true,
  'String': true,
  'bool': true,
  'DateTime': false,
  'List<DateTime>': false,
  'List<int>': true,
  'List<double>': true,
  'List<String>': true,
  'List<bool>': true,
  'Null': true,
};

enum ListType { Object, String, Double, Int, Null }

class MergeableListType {
  final ListType listType;
  final bool isAmbigous;

  MergeableListType(this.listType, this.isAmbigous);
}

MergeableListType mergeableListType(List<dynamic> list) {
  ListType t = ListType.Null;
  bool isAmbigous = false;
  list.forEach((e) {
    final ListType? inferredType = getInferredType(e);
    if (t != ListType.Null && t != inferredType) {
      isAmbigous = true;
    }
    t = inferredType ?? ListType.Null;
  });
  return MergeableListType(t, isAmbigous);
}

ListType? getInferredType(dynamic d) {
  if (d.runtimeType == int) {
    return ListType.Int;
  } else if (d.runtimeType == double) {
    return ListType.Double;
  } else if (d.runtimeType == String) {
    return ListType.String;
  } else if (d is Map) {
    return ListType.Object;
  }
  return null;
}

String camelCase(String text) {
  String capitalize(Match m) =>
      m[0]!.substring(0, 1).toUpperCase() + m[0]!.substring(1);
  String skip(String s) => '';
  return text.splitMapJoin(RegExp('[a-zA-Z0-9]+'),
      onMatch: capitalize, onNonMatch: skip);
}

String camelCaseFirstLower(String text) {
  final String camelCaseText = camelCase(text);
  final String firstChar = camelCaseText.substring(0, 1).toLowerCase();
  final String rest = camelCaseText.substring(1);
  return '$firstChar$rest';
}

dynamic decodeJSON(String rawJson) {
  return Convert.json.decode(rawJson);
}

WithWarning<Map> mergeObj(Map obj, Map other, String path) {
  final List<Warning> warnings = <Warning>[];
  final Map clone = Map.from(obj);
  other.forEach((k, v) {
    if (clone[k] == null) {
      clone[k] = v;
    } else {
      final String otherType = getTypeName(v);
      final String t = getTypeName(clone[k]);
      if (t != otherType) {
        if (t == 'int' && otherType == 'double') {
          // if double was found instead of int, assign the double
          clone[k] = v;
        } else if (clone[k].runtimeType != 'double' && v.runtimeType != 'int') {
          // if types are not equal, then
          warnings.add(newAmbiguousType('$path/$k'));
        }
      } else if (t == 'List') {
        final List l = List.from(clone[k]);
        l.addAll(other[k]);
        final MergeableListType mergeableType = mergeableListType(l);
        if (ListType.Object == mergeableType.listType) {
          final WithWarning<Map> mergedList = mergeObjectList(l, path);
          warnings.addAll(mergedList.warnings);
          clone[k] = List.filled(1, mergedList.result);
        } else {
          if (l.isNotEmpty) {
            clone[k] = List.filled(1, l[0]);
          }
          if (mergeableType.isAmbigous) {
            warnings.add(newAmbiguousType('$path/$k'));
          }
        }
      } else if (t == 'Class') {
        final WithWarning<Map> mergedObj =
            mergeObj(clone[k], other[k], '$path/$k');
        warnings.addAll(mergedObj.warnings);
        clone[k] = mergedObj.result;
      }
    }
  });
  return WithWarning(clone, warnings);
}

WithWarning<Map> mergeObjectList(List<dynamic> list, String path,
    [int idx = -1]) {
  final List<Warning> warnings = <Warning>[];
  final Map obj = {};
  for (int i = 0; i < list.length; i++) {
    final toMerge = list[i];
    if (toMerge is Map) {
      toMerge.forEach((k, v) {
        final String t = getTypeName(obj[k]);
        if (obj[k] == null) {
          obj[k] = v;
        } else {
          final String otherType = getTypeName(v);
          if (t != otherType) {
            if (t == 'int' && otherType == 'double') {
              // if double was found instead of int, assign the double
              obj[k] = v;
            } else if (t != 'double' && otherType != 'int') {
              // if types are not equal, then
              int realIndex = i;
              if (idx != -1) {
                realIndex = idx - i;
              }
              final String ambiguosTypePath = '$path[$realIndex]/$k';
              warnings.add(newAmbiguousType(ambiguosTypePath));
            }
          } else if (t == 'List') {
            final List l = List.from(obj[k]);
            final int beginIndex = l.length;
            l.addAll(v);
            // bug is here
            final MergeableListType mergeableType = mergeableListType(l);
            if (ListType.Object == mergeableType.listType) {
              final WithWarning<Map> mergedList =
                  mergeObjectList(l, '$path[$i]/$k', beginIndex);
              warnings.addAll(mergedList.warnings);
              obj[k] = List.filled(1, mergedList.result);
            } else {
              if (l.isNotEmpty) {
                obj[k] = List.filled(1, l[0]);
              }
              if (mergeableType.isAmbigous) {
                warnings.add(newAmbiguousType('$path[$i]/$k'));
              }
            }
          } else if (t == 'Class') {
            int properIndex = i;
            if (idx != -1) {
              properIndex = i - idx;
            }
            final WithWarning<Map> mergedObj = mergeObj(
              obj[k],
              v,
              '$path[$properIndex]/$k',
            );
            warnings.addAll(mergedObj.warnings);
            obj[k] = mergedObj.result;
          }
        }
      });
    }
  }
  return WithWarning(obj, warnings);
}

bool isPrimitiveType(String typeName) {
  final bool? isPrimitive = PRIMITIVE_TYPES[typeName];
  if (isPrimitive == null) {
    return false;
  }
  return isPrimitive;
}

String fixFieldName(String name,
    {required TypeDefinition typeDef, bool privateField = false}) {
  String properName = name;
  if (name.startsWith('_') || name.startsWith(RegExp('[0-9]'))) {
    final String firstCharType = typeDef.name.substring(0, 1).toLowerCase();
    properName = '$firstCharType$name';
  }
  final String fieldName = camelCaseFirstLower(properName);
  if (privateField) {
    return '_$fieldName';
  }
  return fieldName;
}

String getTypeName(dynamic obj) {
  if (obj is String) {
    return 'String';
  } else if (obj is int) {
    return 'int';
  } else if (obj is double) {
    return 'double';
  } else if (obj is bool) {
    return 'bool';
  } else if (obj == null) {
    return 'Null';
  } else if (obj is List) {
    return 'List';
  } else {
    // assumed class
    return 'Class';
  }
}

Node? navigateNode(Node? astNode, String path) {
  Node? node;
  if (astNode is ObjectNode) {
    final ObjectNode objectNode = astNode;
    PropertyNode? propertyNode;
    for (int i = 0; i < objectNode.children.length; i++) {
      final PropertyNode prop = objectNode.children[i];
      if (prop.key != null && prop.key?.value == path) {
        propertyNode = prop;
        break;
      }
    }
    if (propertyNode != null) {
      node = propertyNode.value;
    }
  }
  if (astNode is ArrayNode) {
    final ArrayNode arrayNode = astNode;
    final int? index = int.tryParse(path);
    if (index != null && arrayNode.children.length > index) {
      node = arrayNode.children[index];
    }
  }
  return node;
}

final RegExp _pattern = RegExp(r'([0-9]+)\.{0,1}([0-9]*)e(([-0-9]+))');

bool isASTLiteralDouble(Node? astNode) {
  if (astNode != null && astNode is LiteralNode) {
    final LiteralNode literalNode = astNode;
    if (literalNode.raw != null) {
      final bool containsPoint = literalNode.raw!.contains('.');
      final bool containsExponent = literalNode.raw!.contains('e');
      if (containsPoint || containsExponent) {
        bool isDouble = containsPoint;
        if (containsExponent) {
          final RegExpMatch? matches = _pattern.firstMatch(literalNode.raw!);
          if (matches != null) {
            final String integer = matches[1]!;
            final String comma = matches[2]!;
            final String exponent = matches[3]!;
            isDouble = _isDoubleWithExponential(integer, comma, exponent);
          }
        }
        return isDouble;
      }
    }
  }
  return false;
}

bool _isDoubleWithExponential(String integer, String comma, String exponent) {
  final int integerNumber = int.tryParse(integer) ?? 0;
  final int exponentNumber = int.tryParse(exponent) ?? 0;
  final int commaNumber = int.tryParse(comma) ?? 0;
  if (exponentNumber == 0) {
    return commaNumber > 0;
  }
  if (exponentNumber > 0) {
    return exponentNumber < comma.length && commaNumber > 0;
  }
  return commaNumber > 0 ||
      ((integerNumber.toDouble() * pow(10, exponentNumber)).remainder(1) > 0);
}
