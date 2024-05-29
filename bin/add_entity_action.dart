import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:dcli/dcli.dart' as dcli;
import 'package:enigma/src/constants/app_constants.dart';
import 'package:enigma/src/extension/string_extension.dart';
import 'package:enigma/src/json_to_dart/model_generator.dart';
import 'package:enigma/src/model/new_entity.dart';
import 'package:enigma/src/services/directory_service.dart';
import 'package:enigma/src/services/file_service.dart';
import 'package:enigma/src/services/input_service.dart';
import 'package:enigma/src/services/script_service.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> addEntityAction([bool debugMode = false]) async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('3.0.0', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();
  final String currentPath = Directory.current.path;
  final String dataDirPath = '$currentPath/data/';
  final String domainDirPath = '$currentPath/domain/';

  String jsonData = '';
  while (jsonData.isEmpty) {
    try {
      final String data = InputService.getMultilineInput(
        'Enter json for class generation (ex: {"name" : "Ivan", ...}) : ',
      );
      jsonData = jsonEncode(jsonDecode(data));
    } catch (e) {
      stdout.writeln(dcli.red('Invalid JSON data'));
    }
  }

  final List<String> generatedClass = ModelGenerator.generateDartClasses(
    className: 'Main',
    rawJson: '$jsonData',
  );

  final List<NewEntity> models = <NewEntity>[];
  for (int i = 0; i < generatedClass.length; i++) {
    final bool isNeedToCreate = logger.chooseOne(
      'Create model for  ${generatedClass[i]}?',
      choices: <String?>[
        AppConstants.kYes,
        AppConstants.kNo,
      ],
    ).toBool();
    if (isNeedToCreate) {
      final String name = InputService.getValidatedInput(
            stdoutMessage:
                'Enter entity name for class (without entity postfix ex: "test data" or "test_data") \n '
                '${generatedClass[i]}'
                ': ',
            errorMessage: AppConstants.kData,
            functionValidator: (String? value) => value?.isNotEmpty,
          ) ??
          '';
      models.add(NewEntity(
        className: name.toCamelCase(),
        fileName: name.snakeCase(),
        rawClass: generatedClass[i],
      ));
    }
  }

  for (int i = 0; i < models.length; i++) {
    if (debugMode) {
      NewEntity newModel = models[i].copyWith(
        isNeedToCreateModel: true,
        isNeedToAddHive: true,
      );
      newModel = newModel.copyWith(
        hiveTypeId: i,
      );
      models.replaceRange(i, i + 1, <NewEntity>[newModel]);
    } else {
      NewEntity newModel = models[i].copyWith(
        isNeedToCreateModel: logger.chooseOne(
          'Create Model and Mapper for ${models[i].className}?',
          choices: <String?>[
            AppConstants.kYes,
            AppConstants.kNo,
          ],
        ).toBool(),
        isNeedToAddHive: logger.chooseOne(
          'Add Hive to entity for ${models[i].className}?',
          choices: <String?>[
            AppConstants.kYes,
            AppConstants.kNo,
          ],
        ).toBool(),
      );

      newModel = newModel.copyWith(
        hiveTypeId: newModel.isNeedToAddHive
            ? InputService.getValidatedInput(
                stdoutMessage: 'Enter Hive Type Id for ${models[i].className}: ',
                errorMessage: AppConstants.kData,
                functionValidator: (String? value) => value?.isNotEmpty,
              ).toInt()
            : 0,
      );
      models.replaceRange(i, i + 1, <NewEntity>[newModel]);
    }
  }

  for (int i = 0; i < models.length; i++) {
    NewEntity model = models[i];

    final String entityContent = '''
      import 'package:freezed_annotation/freezed_annotation.dart';
      ${model.isNeedToAddHive ? "import 'package:hive/hive.dart';" : ""}
      import 'entities.dart';

      part '${model.fileName}_entity.freezed.dart';
      part '${model.fileName}_entity.g.dart';

      @freezed
      ${model.isNeedToAddHive ? "@HiveType(typeId: ${model.hiveTypeId})" : ""}
      class ${model.className}Entity with _\$${model.className}Entity {
        const factory ${model.className}Entity({
          ${model.classFields.map((ClassField e) => e.getFieldString(
              i: model.classFields.indexOf(e) + 1,
              isEntity: true,
              isNeedHive: model.isNeedToAddHive,
              otherModels: models,
            )).toList().join()}
        }) = _${model.className}Entity;

        factory ${model.className}Entity.fromJson(Map<String, dynamic> json) => _\$${model.className}EntityFromJson(json);
      }
      ''';

    final String mapperContent = '''
      import 'package:domain/domain.dart';
      import '../entities/entities.dart';
      import 'mappers.dart';
      
      abstract class ${model.className}Mapper {
        static ${model.className}Model toModel(${model.className}Entity entity) {
          return ${model.className}Model(
             ${model.classFields.map((ClassField e) => e.getMapperString(
              isEntity: true,
              otherModels: models,
            )).toList().join()}
          );
        }
      
        static ${model.className}Entity toEntity(${model.className}Model model) {
          return ${model.className}Entity(
             ${model.classFields.map((ClassField e) => e.getMapperString(
              otherModels: models,
            )).toList().join()}
          );
        }
      }
    ''';

    final String modelContent = '''
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'models.dart';
    
    part '${model.fileName}_model.freezed.dart';
    
    @freezed
    class ${model.className}Model with _\$${model.className}Model {
      factory ${model.className}Model({
         ${model.classFields.map((ClassField e) => e.getFieldString(
              i: model.classFields.indexOf(e) + 1,
              otherModels: models,
            )).toList().join()}
      }) = _${model.className}Model;
    }
    ''';
    final DartFormatter formatter = DartFormatter();

    final File entityFile = File('${dataDirPath}lib/entities/${model.fileName}_entity.dart');
    final File mapperFile = File('${dataDirPath}lib/mapper/${model.fileName}_mapper.dart');
    final File modelFile = File('${domainDirPath}lib/models/${model.fileName}_model.dart');

    if (!entityFile.existsSync()) {
      entityFile.createSync(recursive: true);
      entityFile.writeAsStringSync(formatter.format(entityContent));
      await FileService.addToFile(
          "export '${model.fileName}_entity.dart';", '${dataDirPath}lib/entities/entities.dart');
    }
    if (model.isNeedToCreateModel) {
      if (!mapperFile.existsSync()) {
        mapperFile.createSync(recursive: true);
        mapperFile.writeAsStringSync(formatter.format(mapperContent));
        await FileService.addToFile(
            "export '${model.fileName}_mapper.dart';", '${dataDirPath}lib/mapper/mappers.dart');
      }
      if (!modelFile.existsSync()) {
        modelFile.createSync(recursive: true);
        modelFile.writeAsStringSync(formatter.format(modelContent));
        await FileService.addToFile(
            "export '${model.fileName}_model.dart';", '${domainDirPath}lib/models/models.dart');
      }
    }
  }

  stdout.writeln(dcli.green('✅ Create Successfully!'));
  stdout.writeln(dcli.green('✅ Start build!'));
  await ScriptService.flutterBuild('$dataDirPath');
  await ScriptService.flutterBuild('$domainDirPath');
  stdout.writeln(dcli.green('✅ Build Successfully!'));

  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}

void main() {
  addEntityAction(true);
}
