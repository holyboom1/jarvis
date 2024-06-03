
import 'package:equatable/equatable.dart';

class NewEntity extends Equatable {
  final String fileName;
  final String className;
  final List<ClassField> classFields;
  final int hiveTypeId;
  final bool isNeedToCreateModel;
  final bool isNeedToAddHive;
  final String rawClass;
  final String entityContent;
  final String mapperContent;
  final String modelContent;
  final String genClassName;

  const NewEntity({
    this.fileName = '',
    this.className = '',
    this.classFields = const <ClassField>[],
    this.hiveTypeId = 0,
    this.isNeedToCreateModel = false,
    this.isNeedToAddHive = false,
    this.rawClass = '',
    this.genClassName = '',
    this.entityContent = '',
    this.mapperContent = '',
    this.modelContent = '',
  });

  NewEntity copyWith({
    String? fileName,
    String? className,
    int? hiveTypeId,
    bool? isNeedToCreateModel,
    bool? isNeedToAddHive,
    String? rawClass,
    String? entityContent,
    String? mapperContent,
    String? modelContent,
  }) {
    return NewEntity(
      fileName: fileName ?? this.fileName,
      className: className ?? this.className,
      classFields: _setClassFields(),
      hiveTypeId: hiveTypeId ?? this.hiveTypeId,
      isNeedToCreateModel: isNeedToCreateModel ?? this.isNeedToCreateModel,
      isNeedToAddHive: isNeedToAddHive ?? this.isNeedToAddHive,
      rawClass: rawClass ?? this.rawClass,
      genClassName: this.rawClass.isNotEmpty ? this.rawClass.trim().split(' ')[1] : '',
      entityContent: entityContent ?? this.entityContent,
      mapperContent: mapperContent ?? this.mapperContent,
      modelContent: modelContent ?? this.modelContent,
    );
  }

  List<ClassField> _setClassFields() {
    if (rawClass.isEmpty) {
      return <ClassField>[];
    }
    final String genClassName = rawClass.trim().split(' ')[1];
    final List<String> classFields =
        rawClass.split('{')[1].replaceAll('$genClassName(', '').split(';');
    final List<String> finalClassFields = <String>[];
    for (int i = 0; i < classFields.length; i++) {
      final String field = classFields[i].trim().replaceAll('?', '');
      if (field.isNotEmpty) {
        finalClassFields.add(field);
      }
    }

    return finalClassFields.map(ClassField.fromString).toList();
  }

  @override
  List<Object?> get props => <Object?>[
        fileName,
        className,
        classFields,
        hiveTypeId,
        isNeedToCreateModel,
        isNeedToAddHive,
        rawClass,
        genClassName,
        entityContent,
        mapperContent,
        modelContent,
      ];
}

class ClassField extends Equatable {
  final DartTypes type;
  final DartTypes? subType;
  final String? subName;
  final String name;

  final String customType;

  const ClassField({
    required this.type,
    required this.name,
    this.subName,
    this.subType,
    this.customType = '',
  });

  factory ClassField.fromString(String field) {
    final List<String> fieldList = field.split(' ');
    final ({DartTypes mainType, DartTypes? subType}) type = DartTypes.fromString(fieldList[0]);
    String? subName;
    if (type.subType != null) {
      subName = fieldList[0].split('<')[1].split('>')[0];
    }
    final String name = fieldList[1];
    String customType = '';
    if (type.mainType == DartTypes.custom) {
      customType = fieldList[0];
    }

    return ClassField(
      type: type.mainType,
      subType: type.subType,
      name: name,
      subName: subName,
      customType: customType,
    );
  }

  String getFieldString({
    bool isNeedHive = false,
    int i = 0,
    bool isEntity = false,
    required List<NewEntity> otherModels,
  }) {
    final String classType;
    final String defaultVal;
    if (type == DartTypes.listCustom &&
        subType != DartTypes.custom &&
        subType != DartTypes.listCustom &&
        subType != null) {
      defaultVal = 'const <${subType!.value}>[]';
      classType = 'List<${subType!.value}> $name';
    } else if (type == DartTypes.listCustom) {
      final NewEntity subEntity =
          otherModels.firstWhere((NewEntity e) => e.genClassName == subName);
      defaultVal = 'const <${subEntity.className}${isEntity ? 'Entity' : 'Model'}>[]';
      classType = 'List<${subEntity.className}${isEntity ? 'Entity' : 'Model'}> $name';
    } else if (type == DartTypes.custom) {
      final NewEntity entity =
          otherModels.firstWhere((NewEntity e) => e.genClassName == customType);
      defaultVal = '${entity.className}${isEntity ? 'Entity' : 'Model'}()';
      classType = '${entity.className}${isEntity ? 'Entity' : 'Model'} $name';
    } else {
      defaultVal = type.defaultValue;
      classType = '${type.value} $name';
    }
    return '${isNeedHive ? '@HiveField($i)' : ''} ${isEntity ? '@Default($defaultVal)' : 'required'} $classType,\n';
  }

  String getMapperString({
    bool isEntity = false,
    required List<NewEntity> otherModels,
  }) {
    final String fieldName = name;
    final String mapperValue;
    if (type == DartTypes.listCustom &&
        subType != DartTypes.custom &&
        subType != DartTypes.listCustom &&
        subType != null) {
      mapperValue = '<${subType!.value}>[...${isEntity ? 'entity' : 'model'}.$name]';
    } else if (type == DartTypes.listCustom) {
      final NewEntity subEntity =
          otherModels.firstWhere((NewEntity e) => e.genClassName == subName);
      mapperValue =
          '${isEntity ? 'entity' : 'model'}.$name.map(${subEntity.className}Mapper.to${isEntity ? 'Model' : 'Entity'}).toList()';
    } else if (type == DartTypes.custom) {
      final NewEntity subEntity =
          otherModels.firstWhere((NewEntity e) => e.genClassName == customType);
      mapperValue =
          '${subEntity.className}Mapper.to${isEntity ? 'Model' : 'Entity'}(${isEntity ? 'entity' : 'model'}.$name)';
    } else {
      mapperValue = '${isEntity ? 'entity' : 'model'}.$name';
    }
    return '$fieldName: $mapperValue,\n';
  }

  @override
  List<Object?> get props => <Object?>[
        type,
        subType,
        name,
        subName,
      ];
}

enum DartTypes {
  int('int', '0'),
  double('double', '0.0'),
  string('String', "''"),
  bool('bool', 'false'),
  listCustom('List<custom>', '[]'),
  custom('custom', 'custom');

  final String value;
  final dynamic defaultValue;

  const DartTypes(this.value, this.defaultValue);

  static ({DartTypes mainType, DartTypes? subType}) fromString(String type) {
    if (type.startsWith('List<')) {
      final String subType = type.split('<')[1].split('>')[0];
      return (mainType: DartTypes.listCustom, subType: DartTypes.fromString(subType).mainType);
    }
    switch (type) {
      case 'int':
        return (mainType: DartTypes.int, subType: null);
      case 'double':
        return (mainType: DartTypes.double, subType: null);
      case 'String':
        return (mainType: DartTypes.string, subType: null);
      case 'bool':
        return (mainType: DartTypes.bool, subType: null);
      default:
        return (mainType: DartTypes.custom, subType: null);
    }
  }
}
