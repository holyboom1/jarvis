import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:jarvis/src/constants/app_constants.dart';
import 'package:jarvis/src/extension/string_extension.dart';
import 'package:jarvis/src/services/file_service.dart';
import 'package:jarvis/src/services/input_service.dart';
import 'package:jarvis/src/services/script_service.dart';

Future<void> addRepoAction() async {
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  const String domainDirName = 'domain';
  const String dataDirName = 'data';
  // Initialize the variables with default values
  String path = AppConstants.kCurrentPath;
  if (!path.endsWith('domain')) {
    if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
    } else if (Directory.current.path.contains('domain')) {
      path = Directory.current.path.split('domain')[0];
    } else {
      Directory.current.listSync().forEach((FileSystemEntity element) {
        if (element.path.contains('domain')) {
          path = element.path.split('domain')[0];
        }
        if (element.path.contains('domain')) {
          path = element.path.split('domain')[0];
        }
      });
    }
  }

  if (!path.endsWith('/')) {
    path = '$path/';
  }
  final String domainPath = '${AppConstants.kCurrentPath}/$domainDirName/';
  final String dataPath = '${AppConstants.kCurrentPath}/$dataDirName/';

  final String? repositoryName = InputService.getValidatedInput(
    stdoutMessage: 'Enter a repository name (User without Repository postfix): ',
    errorMessage: AppConstants.kData,
  );

  final String repoAbsContent = '''
    import '../domain.dart';

    abstract class ${repositoryName}Repository {
    
    }

    ''';

  final String repoImplContent = '''
           import 'package:core/core.dart';
        import 'package:domain/domain.dart';
        
        import '../data.dart';
        
        class ${repositoryName}RepositoryImpl implements ${repositoryName}Repository {
         
        }
    ''';

  final File repoAbsFile =
      File('$domainPath/lib/repositories/${repositoryName.snakeCase()}_repository.dart');
  final File repoImplFile =
      File('$dataPath/lib/repositories/${repositoryName.snakeCase()}_repository_impl.dart');

  if (!repoAbsFile.existsSync()) {
    repoAbsFile.createSync(recursive: true);
    repoAbsFile.writeAsStringSync(repoAbsContent);
    await FileService.addToFile("export '${repositoryName.snakeCase()}_repository.dart';",
        '$domainPath/lib/repositories/repositories.dart');
  }

  if (!repoImplFile.existsSync()) {
    repoImplFile.createSync(recursive: true);
    repoImplFile.writeAsStringSync(repoImplContent);
    await FileService.addToFile("export '${repositoryName.snakeCase()}_repository_impl.dart';",
        '$dataPath/lib/repositories/repositories.dart');
  }

  stdout.writeln(dcli.green('✅ Create Successfully!'));
  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}
