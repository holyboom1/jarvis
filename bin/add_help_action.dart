import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:jarvis/src/constants/app_constants.dart';
import 'package:jarvis/src/services/script_service.dart';

Future<void> helpAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  stdout.writeln(dcli.green('➡️ DevPilot Help ⬅️'));
  stdout.writeln(dcli.green('🔹 create: Create a new project'));
  stdout.writeln(dcli.green(
      '🔹 module: Add a new module with bloc, event, state, and view and add this module to the router'));
  stdout.writeln(
      dcli.green('🔹 entity: Add a new entity with models and mapper'));
  stdout.writeln(dcli.green('🔹 usecase: Add a new usecase'));
  stdout.writeln(dcli.green('🔹 repo: Add a new repository'));
  stdout.writeln(dcli.green('🔚 help: Show this help message'));
}
