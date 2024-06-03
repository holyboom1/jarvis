import 'dart:collection';

import 'package:dart_style/dart_style.dart';
import 'package:json_ast/json_ast.dart' show Node;

import 'helpers.dart';
import 'syntax.dart';

class ModelGenerator {
  final bool _privateFields;
  List<ClassDefinition> allClasses = <ClassDefinition>[];
  final Map<String, String> sameClassMapping = HashMap<String, String>();

  ModelGenerator([this._privateFields = false]);

  List<Warning> _generateClassDefinition(
      String className, dynamic jsonRawDynamicData, String path, Node? astNode) {
    final List<Warning> warnings = <Warning>[];
    if (jsonRawDynamicData is List) {
      final Node? node = navigateNode(astNode, '0');
      _generateClassDefinition(className, jsonRawDynamicData[0], path, node);
    } else {
      final Map<dynamic, dynamic> jsonRawData = jsonRawDynamicData;
      final Iterable keys = jsonRawData.keys;
      final ClassDefinition classDefinition = ClassDefinition(className, _privateFields);
      keys.forEach((key) {
        final Node? node = navigateNode(astNode, key);
        final TypeDefinition typeDef = TypeDefinition.fromDynamic(jsonRawData[key], node);
        if (typeDef.name == 'Class') {
          typeDef.name = camelCase(key);
        }
        if (typeDef.name == 'List' && typeDef.subtype == 'Null') {
          warnings.add(newEmptyListWarn('$path/$key'));
        }
        if (typeDef.subtype != null && typeDef.subtype == 'Class') {
          typeDef.subtype = camelCase(key);
        }
        if (typeDef.isAmbiguous) {
          warnings.add(newAmbiguousListWarn('$path/$key'));
        }
        classDefinition.addField(key, typeDef);
      });
      final ClassDefinition similarClass = allClasses.firstWhere(
          (ClassDefinition cd) => cd == classDefinition,
          orElse: () => ClassDefinition(''));
      if (similarClass.name != '') {
        final String similarClassName = similarClass.name;
        final String currentClassName = classDefinition.name;
        sameClassMapping[currentClassName] = similarClassName;
      } else {
        allClasses.add(classDefinition);
      }
      final List<Dependency> dependencies = classDefinition.dependencies;
      dependencies.forEach((Dependency dependency) {
        List<Warning> warns = <Warning>[];
        if (dependency.typeDef.name == 'List') {
          // only generate dependency class if the array is not empty
          if (jsonRawData[dependency.name].length > 0) {
            // when list has ambiguous values, take the first one, otherwise merge all objects
            // into a single one
            dynamic toAnalyze;
            if (!dependency.typeDef.isAmbiguous) {
              final WithWarning<Map> mergeWithWarning =
                  mergeObjectList(jsonRawData[dependency.name], '$path/${dependency.name}');
              toAnalyze = mergeWithWarning.result;
              warnings.addAll(mergeWithWarning.warnings);
            } else {
              toAnalyze = jsonRawData[dependency.name][0];
            }
            final Node? node = navigateNode(astNode, dependency.name);
            warns = _generateClassDefinition(
                dependency.className, toAnalyze, '$path/${dependency.name}', node);
          }
        } else {
          final Node? node = navigateNode(astNode, dependency.name);
          warns = _generateClassDefinition(
              dependency.className, jsonRawData[dependency.name], '$path/${dependency.name}', node);
        }
        warnings.addAll(warns);
      });
    }
    return warnings;
  }

  /// generateUnsafeDart will generate all classes and append one after another
  /// in a single string. The [rawJson] param is assumed to be a properly
  /// formatted JSON string. The dart code is not validated so invalid dart code
  /// might be returned
  String generateUnsafeDart(String rawJson) {
    allClasses.forEach((ClassDefinition c) {
      final Iterable<String> fieldsKeys = c.fields.keys;
      fieldsKeys.forEach((String f) {
        final TypeDefinition? typeForField = c.fields[f];
        if (typeForField != null) {
          if (sameClassMapping.containsKey(typeForField.name)) {
            c.fields[f]!.name = sameClassMapping[typeForField.name]!;
          }
        }
      });
    });
    return allClasses.map((ClassDefinition c) => c.toString()).join('\n');
  }

  /// generateDartClasses will generate all classes and append one after another
  /// in a single string. The [rawJson] param is assumed to be a properly
  /// formatted JSON string. If the generated dart is invalid it will throw an error.
  static List<String> generateDartClasses({
    required String rawJson,
  }) {
    final ModelGenerator modelGenerator = ModelGenerator();
    final String unsafeDartCode = modelGenerator.generateUnsafeDart(rawJson);
    final DartFormatter formatter = DartFormatter();
    final String formattedDartCode =
        formatter.format(unsafeDartCode).replaceAll('class', 'new class');
    return formattedDartCode.split('new')..removeAt(0);
  }
}
