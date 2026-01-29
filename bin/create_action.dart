import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:jarvis/src/constants/app_constants.dart';
import 'package:jarvis/src/enums/template_type.dart';
import 'package:jarvis/src/services/app_add_util.dart';
import 'package:jarvis/src/services/directory_service.dart';
import 'package:jarvis/src/services/input_service.dart';
import 'package:jarvis/src/services/script_service.dart';
import 'package:jarvis/src/validators/validator.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> createAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();

  // Initialize the variables with default values
  String? path = AppConstants.kCurrentPath;

  // Get project name from user input
  final String? projectName = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kEnterProjectName,
    errorMessage: AppConstants.kEnterValidProjectName,
    functionValidator: Validator.kIsValidProjectName,
  );

  // Ask user if  want to specify a path
  final String? specifyPath = logger.chooseOne(
    AppConstants.kNeedSpecifyPath,
    choices: <String?>[
      AppConstants.kYes,
      AppConstants.kNo,
    ],
  );

  // If user selects to specify a path, get the path from user input
  if (specifyPath == AppConstants.kYes) {
    path = InputService.getValidatedInput(
      stdoutMessage: AppConstants.kEnterPath,
      errorMessage: AppConstants.kInvalidPath,
      functionValidator: Validator.kIsValidPath,
    );
  }

  final String? appName = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kAppName,
    errorMessage: AppConstants.kData,
    functionValidator: Validator.kIsValidAppName,
  );
  final String? appIOSBundle = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kAppIOSBundle,
    errorMessage: AppConstants.kData,
    functionValidator: Validator.kIsValidIosBundleId,
  );
  final String? appAndroidBundle = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kAppAndroidBundle,
    errorMessage: AppConstants.kData,
    functionValidator: Validator.kIsValidAndroidPackage,
  );
  final String? projectDescription = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kProjectDescription,
    errorMessage: AppConstants.kData,
  );
  final String? jiraProjectCode = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kJiraProjectPrefix,
    errorMessage: AppConstants.kData,
  );

  final ProcessResult result = Process.runSync(
    'mkdir',
    <String>['-p', '$path/$projectName'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    stdout.writeln(dcli.red(AppConstants.kFailCreateProject(result.stderr)));
  }

  //Clone remote templates repo with folders & files structure
  // to the newly created project directory
  final String scriptPath = Uri.parse(Platform.script.toString()).toFilePath();
  final String scriptDirectory = File(scriptPath).parent.absolute.path;
  final String templatesPath = '$scriptDirectory/templates';

  final Directory templatesDirectory = Directory(templatesPath);
  if (templatesDirectory.existsSync()) {
    Directory(templatesPath).deleteSync(recursive: true);
  }

  final String templateChoice = logger.chooseOne(
        'Choose template:',
        choices: TemplateType.displayNames,
      ) ??
      TemplateType.standardAutoRoute.displayName;

  final TemplateType selectedTemplate = TemplateType.fromDisplayName(templateChoice);
  final String templateUrl = selectedTemplate.templateUrl;

  logger.info('Selected template: ${selectedTemplate.displayName}');

  if (!templatesDirectory.existsSync()) {
    await DirectoryService.cloneRepository(
      templateUrl,
      templatesPath,
    );
  }
  await DirectoryService.copy(
    sourcePath: templatesPath,
    destinationPath: '$path/$projectName',
  );

  final Directory gitDir = Directory('$path/$projectName/.git/');
  if (gitDir.existsSync()) {
    gitDir.deleteSync(recursive: true);
  }

  //Delete test file as don't need one for the moment
  DirectoryService.deleteFile(
    directoryPath: '$path/$projectName/test',
    fileName: 'widget_test.dart',
  );

  await AppRenameUtil.changeAppBundleAndName(
    androidBundleId: appAndroidBundle ?? 'com.example.app',
    iosBundleId: appIOSBundle ?? 'com.example.app',
    appName: appName ?? 'App',
    path: '$path/$projectName/',
  );

  await AppRenameUtil.changeProjectName(
    projectName: projectName ?? 'App',
    projectDescription: projectDescription ?? '',
    jiraPrefix: jiraProjectCode ?? 'APP',
    path: '$path/$projectName/',
  );

  await Process.run(
    'open',
    <String>['-a', 'Android Studio', '$path/$projectName'],
  );
  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}
