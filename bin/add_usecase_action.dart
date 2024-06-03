import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:jarvis/src/constants/app_constants.dart';
import 'package:jarvis/src/extension/string_extension.dart';
import 'package:jarvis/src/services/file_service.dart';
import 'package:jarvis/src/services/input_service.dart';
import 'package:jarvis/src/services/script_service.dart';

Future<void> addUseCaseAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  String domainDirName = 'domain';
  // Initialize the variables with default values
  String path = AppConstants.kCurrentPath;
  if (!path.endsWith('domain')) {
    if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
    } else if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
      domainDirName = 'domain';
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
  if (!path.endsWith('/')) {
    path = '$path/';
  }
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

  final File usecaseFile = File('$domainPath/lib/usecases/${useCaseName.snakeCase()}_usecase.dart');

  if (!usecaseFile.existsSync()) {
    usecaseFile.createSync(recursive: true);
    usecaseFile.writeAsStringSync(useCaseContent);
    await FileService.addToFile("export '${useCaseName.snakeCase()}_usecase.dart';",
        '$domainPath/lib/usecases/export_usecases.dart');
  }

  stdout.writeln(dcli.green('✅ Create Successfully!'));
  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}
