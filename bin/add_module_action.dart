import 'dart:io';
import 'package:dcli/dcli.dart' as dcli;
import 'package:dev_pilot/src/constants/app_constants.dart';
import 'package:dev_pilot/src/services/directory_service.dart';
import 'package:dev_pilot/src/services/input_service.dart';
import 'package:dev_pilot/src/services/script_service.dart';
import 'package:dev_pilot/src/validators/validator.dart';
import 'package:mason_logger/mason_logger.dart';

import '../lib/src/services/app_bundle_util.dart';

Future<void> addModuleAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();

  // Initialize the variables with default values
  final String? path = AppConstants.kCurrentPath;
  // Get project name from user input
  final String? moduleName = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kEnterModuleName,
    errorMessage: AppConstants.kInvalidModuleName,
  );

  //Create project with a given name
  final ProcessResult result = Process.runSync(
    'mkdir',
    <String>['-p', '$path/$moduleName'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    stdout.writeln(dcli.red(AppConstants.kFailCreateModule(result.stderr)));
  }

  //Clone remote templates repo with folders & files structure
  // to the newly created project directory
  final String scriptPath = Uri.parse(Platform.script.toString()).toFilePath();
  final String scriptDirectory = File(scriptPath).parent.absolute.path;
  final String templatesModulePath = '$scriptDirectory/templates_module';

  final Directory templatesDirectory = Directory(templatesModulePath);

  if (!templatesDirectory.existsSync()) {
    await DirectoryService.cloneRepository(
      AppConstants.kRemoteModuleTemplatesLink,
      templatesModulePath,
    );
  }
  await DirectoryService.copy(
    sourcePath: templatesModulePath,
    destinationPath: '$path/$moduleName',
  );

  await AppRenameUtil.changeModuleName(
    moduleName: moduleName ?? 'temp',
    path: '$path/$moduleName/',
  );
}
