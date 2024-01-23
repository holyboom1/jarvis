import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:enigma/src/constants/app_constants.dart';

import 'add_module_action.dart';
import 'create_action.dart';

enum Actions {
  create('create'),
  addModule('module');

  final String name;
  const Actions(this.name);
}

// Main method
void main(List<String> arguments) async {
  stdout.write(dcli.green(AppConstants.kLogo));

  // Check if the argument is create
  if (arguments.contains(Actions.create.name)) {
    await createAction();
  } else if (arguments.contains(Actions.addModule.name)) {
    await addModuleAction();
  } else {
    stdout.writeln(dcli.red('Undefined Command'));
  }
}
