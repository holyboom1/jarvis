import 'package:jarvis/src/constants/app_constants.dart';

enum TemplateType {
  standardAutoRoute(
    id: 1,
    displayName: '1) Standard (AutoRoute)',
    templateUrl: AppConstants.kRemoteTemplatesLink,
    moduleUrl: AppConstants.kRemoteModuleTemplatesLink,
    isGoRouter: false,
  ),
  standardGoRouter(
    id: 2,
    displayName: '2) Standard (GoRouter)',
    templateUrl: AppConstants.kRemoteGoTemplatesLink,
    moduleUrl: AppConstants.kRemoteGoModuleTemplatesLink,
    isGoRouter: true,
  ),
  jarvis2AutoRoute(
    id: 3,
    displayName: '3) Jarvis 2.0 AutoRoute',
    templateUrl: AppConstants.kRemoteJarvis2AutoRouteTemplatesLink,
    moduleUrl: AppConstants.kRemoteJarvis2ModuleTemplatesLink,
    isGoRouter: false,
  ),
  jarvis2GoRouter(
    id: 4,
    displayName: '4) Jarvis 2.0 GoRouter',
    templateUrl: AppConstants.kRemoteJarvis2GoRouterTemplatesLink,
    moduleUrl: AppConstants.kRemoteJarvis2GoRouterModuleTemplatesLink,
    isGoRouter: true,
  );

  const TemplateType({
    required this.id,
    required this.displayName,
    required this.templateUrl,
    required this.moduleUrl,
    required this.isGoRouter,
  });

  final int id;
  final String displayName;
  final String templateUrl;
  final String moduleUrl;
  final bool isGoRouter;

  /// Returns true if this is a Jarvis 2.0 template (uses workspace, no android/ios folders in root)
  bool get isJarvis2 => this == jarvis2AutoRoute || this == jarvis2GoRouter;

  static TemplateType fromDisplayName(String displayName) {
    return TemplateType.values.firstWhere(
      (TemplateType type) => type.displayName == displayName,
      orElse: () => TemplateType.standardAutoRoute,
    );
  }

  static List<String> get displayNames {
    return TemplateType.values.map((TemplateType type) => type.displayName).toList();
  }
}