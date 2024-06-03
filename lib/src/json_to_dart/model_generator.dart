import 'dart:collection';

import 'package:dart_style/dart_style.dart';
import 'syntax.dart';

class ModelGenerator {
  List<ClassDefinition> allClasses = <ClassDefinition>[];
  final Map<String, String> sameClassMapping = HashMap<String, String>();

  ModelGenerator();

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
