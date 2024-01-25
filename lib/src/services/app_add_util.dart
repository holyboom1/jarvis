import 'package:enigma/src/constants/app_constants.dart';
import 'package:enigma/src/services/file_service.dart';

class AppRenameUtil {
  static const String _androidBundleKey = '{android_bundle_id}';
  static const String _iosBundleKey = 'app-bundle-id-string';
  static const String _appNameKey = '{app_name}';
  static const String _fileAndroidPath = 'android/app/build.gradle';
  static const String _fileIOSPath = 'ios/Runner.xcodeproj/project.pbxproj';

  static Future<void> changeAppBundleAndName({
    required String androidBundleId,
    required String iosBundleId,
    required String appName,
    required String path,
  }) async {
    await FileService.updateFileContent(
      oldString: _androidBundleKey,
      newString: androidBundleId,
      filePath: path + _fileAndroidPath,
    );

    await FileService.updateFileContent(
      oldString: _appNameKey,
      newString: appName,
      filePath: path + _fileAndroidPath,
    );

    await FileService.updateFileContent(
      oldString: _iosBundleKey,
      newString: iosBundleId,
      filePath: path + _fileIOSPath,
    );

    await FileService.updateFileContent(
      oldString: _appNameKey,
      newString: appName,
      filePath: path + _fileIOSPath,
    );

    await FileService.updateFileContent(
      oldString: _iosBundleKey,
      newString: iosBundleId,
      filePath: path + _fileIOSPath,
    );
  }

  static const String _projectNameKey = '{project_name}';
  static const String _projectDescriptionKey = '{project_description}';
  static const String _projectJiraKey = '{jira_prefix}';

  static const String _readmePath = 'README.md';
  static const String _pubspecPath = 'pubspec.yaml';

  static Future<void> changeProjectName({
    required String projectName,
    required String projectDescription,
    required String jiraPrefix,
    required String path,
  }) async {
    await FileService.updateFileContent(
      oldString: _projectNameKey,
      newString: projectName,
      filePath: path + _readmePath,
    );

    await FileService.updateFileContent(
      oldString: _projectNameKey,
      newString: projectName,
      filePath: path + _pubspecPath,
    );

    await FileService.updateFileContent(
      oldString: _projectDescriptionKey,
      newString: projectDescription,
      filePath: path + _readmePath,
    );

    await FileService.updateFileContent(
      oldString: _projectDescriptionKey,
      newString: projectDescription,
      filePath: path + _pubspecPath,
    );

    await FileService.updateFileContent(
      oldString: _projectJiraKey,
      newString: jiraPrefix.toUpperCase(),
      filePath: path + _readmePath,
    );
  }

  static Future<void> changeModuleName({
    required String moduleName,
    required String path,
  }) async {
    final String moduleClassName;
    if (moduleName.contains('_')) {
      final List<String> moduleClassNameList = moduleName.split('_');
      moduleClassName = moduleClassNameList.map((String e) {
        return e[0].toUpperCase() + e.substring(1);
      }).join();
    } else {
      moduleClassName = moduleName[0].toUpperCase() + moduleName.substring(1);
    }

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}pubspec.yaml',
    );

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}lib/temp.dart',
    );

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}lib/src/screen/temp_screen.dart',
    );

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}lib/src/bloc/temp_bloc.dart',
    );

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}lib/src/bloc/temp_event.dart',
    );

    await FileService.updateFileContent(
      oldString: '{module_name}',
      newString: moduleName,
      filePath: '${path}lib/src/bloc/temp_state.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/src/bloc/temp_bloc.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/src/bloc/temp_event.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/src/bloc/temp_state.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/src/screen/temp_screen.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/temp.dart',
    );

    await FileService.updateFileContent(
      oldString: 'Temp',
      newString: moduleClassName,
      filePath: '${path}lib/src/form/temp_form.dart',
    );

    await FileService.renameFile(
      newName: '${moduleName}_form.dart',
      oldName: 'temp_form.dart',
      path: '${path}lib/src/form/',
    );

    await FileService.renameFile(
      newName: '${moduleName}_bloc.dart',
      oldName: 'temp_bloc.dart',
      path: '${path}lib/src/bloc/',
    );

    await FileService.renameFile(
      newName: '${moduleName}_event.dart',
      oldName: 'temp_event.dart',
      path: '${path}lib/src/bloc/',
    );

    await FileService.renameFile(
      newName: '${moduleName}_state.dart',
      oldName: 'temp_state.dart',
      path: '${path}lib/src/bloc/',
    );

    await FileService.renameFile(
      newName: '${moduleName}_screen.dart',
      oldName: 'temp_screen.dart',
      path: '${path}lib/src/screen/',
    );

    await FileService.renameFile(
      newName: '$moduleName.dart',
      oldName: 'temp.dart',
      path: '${path}lib/',
    );
  }

  static Future<void> addModuleToRouter({
    required String moduleName,
    required String path,
  }) async {
    await FileService.appendToFile(
      '#  Features',
      '  $moduleName: \n    path: ../feature/$moduleName',
      '$path/pubspec.yaml',
    );

    final String moduleClassName;
    if (moduleName.contains('_')) {
      final List<String> moduleClassNameList = moduleName.split('_');
      moduleClassName = moduleClassNameList.map((String e) {
        return e[0].toUpperCase() + e.substring(1);
      }).join();
    } else {
      moduleClassName = moduleName[0].toUpperCase() + moduleName.substring(1);
    }
    await FileService.appendToFile(
      'modules: <Type>[',
      ' \n${moduleClassName}Module,\n',
      '$path/lib/src/app_router/app_router.dart',
    );
    await FileService.appendToFile(
      'final List<AutoRoute> routes = <AutoRoute>[',
      '   AutoRoute(\n    page: ${moduleClassName}Route.page,\n   ),',
      '$path/lib/src/app_router/app_router.dart',
    );
    await FileService.appendToFile(
      "import 'services/route_logger.dart';",
      "export 'package:$moduleName/$moduleName.dart';",
      '$path/lib/src/app_router/app_router.dart',
    );
  }
}
