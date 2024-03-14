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

Future<void> helpAction() async {
  // Check if the Dart version is in the correct range
  if (!await ScriptService.isDartVersionInRange('2.19.5', '4.0.0')) {
    stdout.writeln(dcli.red(AppConstants.kUpdateDartVersion));
    return;
  }

  // Create a new logger
  final Logger logger = Logger();

  stdout.writeln(dcli.green('➡️ DevPilot Help ⬅️'));
  stdout.writeln(dcli.green('🔹 create: Create a new project'));
  stdout.writeln(dcli.green(
      '🔹 module: Add a new module with bloc, event, state, and view and add this module to the router'));
  stdout.writeln(dcli.green('🔹 entity: Add a new entity with models and mapper'));
  stdout.writeln(dcli.green('🔹 usecase: Add a new usecase'));
  stdout.writeln(dcli.green('🔹 repo: Add a new repository'));
  stdout.writeln(dcli.green('🔚 help: Show this help message'));
}
