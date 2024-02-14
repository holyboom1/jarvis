import 'dart:io';

import 'package:dcli/dcli.dart' as dcli;
import 'package:enigma/src/constants/app_constants.dart';

import 'add_entity_action.dart';
import 'add_module_action.dart';
import 'create_action.dart';

enum Actions {
  create('create'),
  addModule('module'),
  addEntity('entity');

  final String name;
  const Actions(this.name);
}

// Main method
void main(List<String> arguments) async {
  stdout.write(dcli.green(AppConstants.kLogo));

  switch (arguments.first) {
    case 'create':
      await createAction();
      break;
    case 'module':
      await addModuleAction();
      break;
    case 'entity':
      await addEntityAction();
      break;
    default:
      stdout.writeln(dcli.red('Undefined Command'));
  }
}
