import 'package:json_ast/json_ast.dart' show Node;

import 'helpers.dart';

const String emptyListWarn = 'list is empty';
const String ambiguousListWarn = 'list is ambiguous';
const String ambiguousTypeWarn = 'type is ambiguous';

class Warning {
  final String warning;
  final String path;

  Warning(this.warning, this.path);
}

Warning newEmptyListWarn(String path) {
  return Warning(emptyListWarn, path);
}

Warning newAmbiguousListWarn(String path) {
  return Warning(ambiguousListWarn, path);
}

Warning newAmbiguousType(String path) {
  return Warning(ambiguousTypeWarn, path);
}

class WithWarning<T> {
  final T result;
  final List<Warning> warnings;

  WithWarning(this.result, this.warnings);
}

class TypeDefinition {
  String name;
  String? subtype;
  bool isAmbiguous = false;
  bool _isPrimitive = false;

  factory TypeDefinition.fromDynamic(dynamic obj, Node? astNode) {
    bool isAmbiguous = false;
    final type = getTypeName(obj);
    if (type == 'List') {
      final List<dynamic> list = obj;
      String elemType;
      if (list.isNotEmpty) {
        elemType = getTypeName(list[0]);
        for (final dynamic listVal in list) {
          final typeName = getTypeName(listVal);
          if (elemType != typeName) {
            isAmbiguous = true;
            break;
          }
        }
      } else {
        // when array is empty insert Null just to warn the user
        elemType = 'Null';
      }
      return TypeDefinition(type,
          astNode: astNode, subtype: elemType, isAmbiguous: isAmbiguous);
    }
    return TypeDefinition(type, astNode: astNode, isAmbiguous: isAmbiguous);
  }

  TypeDefinition(this.name,
      {this.subtype, this.isAmbiguous = false, Node? astNode}) {
    if (subtype == null) {
      _isPrimitive = isPrimitiveType(name);
      if (name == 'int' && isASTLiteralDouble(astNode)) {
        name = 'double';
      }
    } else {
      _isPrimitive = isPrimitiveType('$name<$subtype>');
    }
  }

  @override
  bool operator ==(other) {
    if (other is TypeDefinition) {
      final TypeDefinition otherTypeDef = other;
      return name == otherTypeDef.name &&
          subtype == otherTypeDef.subtype &&
          isAmbiguous == otherTypeDef.isAmbiguous &&
          _isPrimitive == otherTypeDef._isPrimitive;
    }
    return false;
  }

  bool get isPrimitive => _isPrimitive;

  bool get isPrimitiveList => _isPrimitive && name == 'List';

  String _buildParseClass(String expression) {
    final properType = subtype ?? name;
    return 'new $properType.fromJson($expression)';
  }

  String _buildToJsonClass(String expression, [bool nullGuard = true]) {
    if (nullGuard) {
      return '$expression!.toJson()';
    }
    return '$expression.toJson()';
  }

  String jsonParseExpression(String key, bool privateField) {
    final jsonKey = "json['$key']";
    final fieldKey =
        fixFieldName(key, typeDef: this, privateField: privateField);
    if (isPrimitive) {
      if (name == 'List') {
        return "$fieldKey = json['$key'].cast<$subtype>();";
      }
      return "$fieldKey = json['$key'];";
    } else if (name == 'List' && subtype == 'DateTime') {
      return "$fieldKey = json['$key'].map((v) => DateTime.tryParse(v));";
    } else if (name == 'DateTime') {
      return "$fieldKey = DateTime.tryParse(json['$key']);";
    } else if (name == 'List') {
      // list of class
      return "if (json['$key'] != null) {\n\t\t\t$fieldKey = <$subtype>[];\n\t\t\tjson['$key'].forEach((v) { $fieldKey!.add(new $subtype.fromJson(v)); });\n\t\t}";
    } else {
      // class
      return "$fieldKey = json['$key'] != null ? ${_buildParseClass(jsonKey)} : null;";
    }
  }

  String toJsonExpression(String key, bool privateField) {
    final fieldKey =
        fixFieldName(key, typeDef: this, privateField: privateField);
    final thisKey = 'this.$fieldKey';
    if (isPrimitive) {
      return "data['$key'] = $thisKey;";
    } else if (name == 'List') {
      // class list
      return """if ($thisKey != null) {
      data['$key'] = $thisKey!.map((v) => ${_buildToJsonClass('v', false)}).toList();
    }""";
    } else {
      // class
      return """if ($thisKey != null) {
      data['$key'] = ${_buildToJsonClass(thisKey)};
    }""";
    }
  }
}

class Dependency {
  String name;
  final TypeDefinition typeDef;

  Dependency(this.name, this.typeDef);

  String get className => camelCase(name);
}

class ClassDefinition {
  final String _name;
  final bool _privateFields;
  final Map<String, TypeDefinition> fields = <String, TypeDefinition>{};

  String get name => _name;
  bool get privateFields => _privateFields;

  List<Dependency> get dependencies {
    final dependenciesList = <Dependency>[];
    final keys = fields.keys;
    keys.forEach((k) {
      final f = fields[k];
      if (f != null && !f.isPrimitive) {
        dependenciesList.add(Dependency(k, f));
      }
    });
    return dependenciesList;
  }

  ClassDefinition(this._name, [this._privateFields = false]);

  @override
  bool operator ==(other) {
    if (other is ClassDefinition) {
      final ClassDefinition otherClassDef = other;
      return isSubsetOf(otherClassDef) && otherClassDef.isSubsetOf(this);
    }
    return false;
  }

  bool isSubsetOf(ClassDefinition other) {
    final List<String> keys = fields.keys.toList();
    final int len = keys.length;
    for (int i = 0; i < len; i++) {
      final TypeDefinition? otherTypeDef = other.fields[keys[i]];
      if (otherTypeDef != null) {
        final TypeDefinition? typeDef = fields[keys[i]];
        if (typeDef != otherTypeDef) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  bool hasField(TypeDefinition otherField) {
    final key = fields.keys
        .firstWhere((k) => fields[k] == otherField, orElse: () => '');
    return key != '';
  }

  addField(String name, TypeDefinition typeDef) {
    fields[name] = typeDef;
  }

  void _addTypeDef(TypeDefinition typeDef, StringBuffer sb) {
    sb.write(typeDef.name);
    if (typeDef.subtype != null) {
      sb.write('<${typeDef.subtype}>');
    }
  }

  String get _fieldList {
    return fields.keys.map((key) {
      final f = fields[key]!;
      final fieldName =
          fixFieldName(key, typeDef: f, privateField: privateFields);
      final sb = StringBuffer();
      sb.write('\t');
      _addTypeDef(f, sb);
      sb.write('? $fieldName;');
      return sb.toString();
    }).join('\n');
  }

  String get _gettersSetters {
    return fields.keys.map((key) {
      final f = fields[key]!;
      final publicFieldName = fixFieldName(key, typeDef: f);
      final privateFieldName =
          fixFieldName(key, typeDef: f, privateField: true);
      final sb = StringBuffer();
      sb.write('\t');
      _addTypeDef(f, sb);
      sb.write(
          '? get $publicFieldName => $privateFieldName;\n\tset $publicFieldName(');
      _addTypeDef(f, sb);
      sb.write('? $publicFieldName) => $privateFieldName = $publicFieldName;');
      return sb.toString();
    }).join('\n');
  }

  String get _defaultPrivateConstructor {
    final sb = StringBuffer();
    sb.write('\t$name({');
    var i = 0;
    final len = fields.keys.length - 1;
    fields.keys.forEach((key) {
      final f = fields[key]!;
      final publicFieldName = fixFieldName(key, typeDef: f);
      _addTypeDef(f, sb);
      sb.write('? $publicFieldName');
      if (i != len) {
        sb.write(', ');
      }
      i++;
    });
    sb.write('}) {\n');
    fields.keys.forEach((key) {
      final f = fields[key]!;
      final publicFieldName = fixFieldName(key, typeDef: f);
      final privateFieldName =
          fixFieldName(key, typeDef: f, privateField: true);
      sb.write('if ($publicFieldName != null) {\n');
      sb.write('this.$privateFieldName = $publicFieldName;\n');
      sb.write('}\n');
    });
    sb.write('}');
    return sb.toString();
  }

  String get _defaultConstructor {
    final sb = StringBuffer();
    sb.write('\t$name({');
    var i = 0;
    final len = fields.keys.length - 1;
    fields.keys.forEach((key) {
      final f = fields[key]!;
      final fieldName =
          fixFieldName(key, typeDef: f, privateField: privateFields);
      sb.write('this.$fieldName');
      if (i != len) {
        sb.write(', ');
      }
      i++;
    });
    sb.write('});');
    return sb.toString();
  }

  @override
  String toString() {
    if (privateFields) {
      return 'class $name {\n$_fieldList\n\n$_defaultPrivateConstructor\n\n$_gettersSetters\n\n}\n';
    } else {
      return 'class $name {\n$_fieldList\n\n$_defaultConstructor\n\n}\n';
    }
  }
}
