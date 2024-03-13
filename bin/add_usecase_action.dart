import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:enigma/src/constants/app_constants.dart';
import 'package:enigma/src/extension/string_extension.dart';
import 'package:enigma/src/services/directory_service.dart';
import 'package:enigma/src/services/file_service.dart';
import 'package:enigma/src/services/input_service.dart';
import 'package:enigma/src/services/script_service.dart';
import 'package:enigma/src/validators/validator.dart';
import 'package:mason_logger/mason_logger.dart';

import '../lib/src/services/app_add_util.dart';

Future<void> addUseCaseAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();
  String domainDirName = 'domain';
  // Initialize the variables with default values
  String path = AppConstants.kCurrentPath;
  if (!path.endsWith('domain')) {
    if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
    } else if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
      domainDirName = 'features';
    } else {
      Directory.current.listSync().forEach((FileSystemEntity element) {
        if (element.path.contains('domain')) {
          path = element.path.split('domain')[0];
        }
        if (element.path.contains('domain')) {
          path = element.path.split('domain')[0];
          domainDirName = 'domain';
        }
      });
    }
  }
  path.endsWith('/') ? path : path = '$path/';
  final String domainPath = '${AppConstants.kCurrentPath}/$domainDirName/';

  // Get project name from user input
  final String? useCaseName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a usecase name (GetUser): ',
    errorMessage: AppConstants.kData,
  );

  final String? repositoryName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a repository name (UserRepository): ',
    errorMessage: AppConstants.kData,
  );

  final String? returnTypeName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a return type name (User): ',
    errorMessage: AppConstants.kData,
  );

  final String? inputTypeName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a input type name (String or NoParams): ',
    errorMessage: AppConstants.kData,
  );

  final String? methodName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a method name (getUser): ',
    errorMessage: AppConstants.kData,
  );

  final String useCaseContent = '''
    import '../../domain.dart';

    class ${useCaseName}UseCase implements FutureUseCase<$inputTypeName, $returnTypeName> {
      final $repositoryName _repository;
    
      ${useCaseName}UseCase({
        required $repositoryName repository,
      }) : _repository = repository;
    
      @override
      Future<$returnTypeName> execute($inputTypeName input) {
        return _repository.$methodName();
      }
    }

    ''';

  final File usecaseFile =
      File('${domainPath}/lib/useceses/${useCaseName.snakeCase()}_usecase.dart');

  if (!usecaseFile.existsSync()) {
    usecaseFile.createSync(recursive: true);
    usecaseFile.writeAsStringSync(useCaseContent);
    await FileService.addToFile("export '${useCaseName.snakeCase()}_usecase.dart';",
        '${domainPath}/lib/useceses/export_usecases.dart');
  }

  stdout.writeln(dcli.green('✅ Create Successfully!'));
  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}
