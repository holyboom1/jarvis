import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:jarvis/src/constants/app_constants.dart';
import 'package:jarvis/src/extension/string_extension.dart';
import 'package:jarvis/src/services/app_add_util.dart';
import 'package:jarvis/src/services/directory_service.dart';
import 'package:jarvis/src/services/input_service.dart';
import 'package:jarvis/src/services/script_service.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> addModuleAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();
  String futureDirName = 'feature';

  // Initialize the variables with default values
  String path = AppConstants.kCurrentPath;
  if (!path.endsWith('feature')) {
    if (Directory.current.path.contains('feature')) {
      path = Directory.current.path.split('feature')[0];
    } else if (Directory.current.path.contains('features')) {
      path = Directory.current.path.split('features')[0];
      futureDirName = 'features';
    } else {
      Directory.current.listSync().forEach((FileSystemEntity element) {
        if (element.path.contains('feature')) {
          path = element.path.split('feature')[0];
        }
        if (element.path.contains('features')) {
          path = element.path.split('features')[0];
          futureDirName = 'features';
        }
      });
    }
  }
  if (!path.endsWith('/')) {
    path = '$path/';
  }
  final String featurePath = '${AppConstants.kCurrentPath}/$futureDirName/';

  // Get project name from user input
  final String? moduleName = InputService.getValidatedInput(
    stdoutMessage: AppConstants.kEnterModuleName,
    errorMessage: AppConstants.kInvalidModuleName,
  );

  final bool addToRouter = logger.chooseOne(
    AppConstants.kAddToRouter,
    choices: <String?>[
      AppConstants.kYes,
      AppConstants.kNo,
    ],
  ).toBool();

  //Create project with a given name
  final ProcessResult result = Process.runSync(
    'mkdir',
    <String>['-p', '$featurePath/$moduleName'],
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
  if (templatesDirectory.existsSync()) {
    Directory(templatesModulePath).deleteSync(recursive: true);
  }

  // Detect if this is a Jarvis 2.0 project
  final File pubspecFile = File('${path}pubspec.yaml');
  bool isJarvis2Project = false;

  if (pubspecFile.existsSync()) {
    final String pubspecContent = pubspecFile.readAsStringSync();
    if (pubspecContent.contains('workspace:')) {
      isJarvis2Project = true;
    }
  }

  String moduleTemplateUrl;

  if (isJarvis2Project) {
    moduleTemplateUrl = AppConstants.kRemoteJarvis2ModuleTemplatesLink;
    logger.info('✅ Detected Jarvis 2.0 project, using Jarvis 2.0 module template');
  } else {
    final bool isGoRouter = logger.chooseOne(
      AppConstants.kGoRouter,
      choices: <String?>[
        AppConstants.kYes,
        AppConstants.kNo,
      ],
    ).toBool();

    moduleTemplateUrl = isGoRouter
        ? AppConstants.kRemoteGoModuleTemplatesLink
        : AppConstants.kRemoteModuleTemplatesLink;
  }

  if (!templatesDirectory.existsSync()) {
    await DirectoryService.cloneRepository(
      moduleTemplateUrl,
      templatesModulePath,
    );
  }
  await DirectoryService.copy(
    sourcePath: templatesModulePath,
    destinationPath: '$featurePath/$moduleName',
  );

  await AppRenameUtil.changeModuleName(
    moduleName: moduleName ?? 'temp',
    path: '$featurePath/$moduleName/',
  );

  final Directory gitDir = Directory('$featurePath/$moduleName/.git/');
  if (gitDir.existsSync()) {
    stdout.writeln(dcli.green('✅ Remove GIT!'));
    gitDir.deleteSync(recursive: true);
  }

  stdout.writeln(dcli.green('✅ Create Successfully!'));
  stdout.writeln(dcli.green('✅ Start build!'));
  await ScriptService.flutterPubGet('$featurePath/$moduleName/');
  await ScriptService.flutterBuild('$featurePath/$moduleName/');
  stdout.writeln(dcli.green('✅ Build Successfully!'));

  if (addToRouter) {
    stdout.writeln(dcli.green('✅ Start adding to router!'));
    final String navigationPath = '${path}navigation/';
    await AppRenameUtil.addModuleToRouter(
      isGoRouter: isGoRouter,
      moduleName: moduleName ?? 'temp',
      path: navigationPath,
      modulePath: '$featurePath/$moduleName/',
    );
    stdout.writeln(dcli.green('✅ Added Successfully!'));
    stdout.writeln(dcli.green('✅ Start navigation build!'));
    await ScriptService.flutterPubGet(navigationPath);
    await ScriptService.flutterBuild(navigationPath);
    stdout.writeln(dcli.green('✅ Navigation Build Successfully!'));

    stdout.writeln(dcli.green('✅ Start core build!'));
    await ScriptService.flutterPubGet('${path}core');
    await ScriptService.flutterBuild('${path}core');
    stdout.writeln(dcli.green('✅ Core Build Successfully!'));
  }

  stdout.writeln(dcli.green('✅ Finish Successfully!'));
}
