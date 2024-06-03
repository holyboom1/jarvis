import 'dart:io';

class AppConstants {
  //STRING CONSTANTS
  static const String kEnterProjectName = 'Enter a project name: ';
  static const String kEnterModuleName = 'Enter a module name (example_module): ';
  static const String kUpdateDartVersion =
      'Your Dart SDK version is not supported. Please upgrade to a version >=2.19.5 and <3.1.0';
  static const String kEnterValidProjectName =
      'Please enter a valid project name (full string or snake case string): ';
  static const String kNeedSpecifyPath =
      'Do you need specify path ? Note if you select "no" project will be created in a current location (Yes/No): ';
  static const String kEnterPath = 'Please specify the path where you want to create the project: ';
  static const String kAddToRouter = 'Add new module to router : ';
  static const String kAppName = 'Please specify the app display name: ';
  static const String kAppIOSBundle = 'Please specify ios bundle id: ';
  static const String kAppAndroidBundle = 'Please specify android bundle id: ';
  static const String kProjectDescription = 'Please specify project description: ';
  static const String kJiraProjectPrefix = 'Please specify jira project prefix: ';
  static const String kInvalidPath = 'Invalid path. Please specify a valid path: ';
  static const String kData = 'Invalid value ';
  static const String kAddFeature = 'Do you want add features now? (Yes/No): ';
  static const String kYes = 'yes';
  static const String kNo = 'no';
  static const String kInvalidYesOrNo = 'Invalid input. Please enter "yes" or "no": ';
  static const String kEnterFeatures =
      'Please enter all required feature modules separated by commas : ';
  static const String kInvalidFeatureName =
      'Invalid feature modules input. Please enter full string or snake case strings separated by commas : ';
  static const String kWillYouUseDio = 'Will you use Dio in your project? (yes/no) ';

  static String kAddPackages(String modulesString) {
    return 'Do you want to add any packages to any of the following modules (core, core_ui, data, domain, navigation, features ${modulesString.isEmpty ? '' : <String>[
        modulesString
      ]})? (yes/no): ';
  }

  static String kSelectModule(String modulesString) {
    return 'Please select a module from the following list to add packages to (core, core_ui, data, domain, navigation, features ${modulesString.isEmpty ? '' : <String>[
        modulesString
      ]} ) : ';
  }

  static String kAddPackageSelectModule(String? selectedModule) {
    return 'Please enter the packages you want to add to ${selectedModule ?? ''} module (comma-separated): ';
  }

  static String kAddPackageFeatureModule(String? featureName) {
    return 'Please enter the packages you want to add to the $featureName feature (comma-separated): ';
  }

  static String kFailCreateProject(String? error) {
    return 'Failed to create Flutter project: $error';
  }

  static String kFailCreateModule(String? error) {
    return 'Failed to create Flutter module: $error';
  }

  static const String kEnterFeatureForPackage =
      'Please enter the feature name for which you want to add packages: ';
  static const String kInvalidFeatureForPackage =
      'Invalid feature name entered. Please try again.\n';
  static const String kInvalidModuleName = 'Invalid module name entered. Please try again.\n';
  static const String kAddPackageOtherModule =
      'Do you want to add packages to any other module? (yes/no): ';
  static const String kInvalidPackage = 'Invalid Package input please try again: ';

  static String kCurrentPath = Directory.current.path;

  static const String kFeaturePlug = 'name: plug';

  static String kFeaturePlugReplaceWith(String? featureName) {
    return 'name: $featureName';
  }

  static String kInvalidSourceFolder(String folder) {
    return '$folder folder does not exist';
  }

  static const String kRemoteTemplatesLink = 'https://github.com/holyboom1/dev_pilot_template';
  static const String kRemoteModuleTemplatesLink =
      'https://github.com/holyboom1/dev_pilot_module_template.git';

  static const String kLogo = '''
    👾🅓🅔🅥🅟🅘🅛🅞🅣👾
  ''';
}
