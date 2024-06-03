# Jarvis Modularity Assistant
#### _Command-line interface (CLI) for generating a Flutter project_


It prompts the user for input and then creates a Flutter project with the given specifications. The generated project will include a set of predefined modules, such as
- Core
- CoreUi
- Data
- Domain
- Navigation

The user can also specify additional
- Features
- Flavors
- Packages

The code uses the [dcli](https://pub.dev/packages/dcli) and [mason_logger](https://pub.dev/packages/mason_logger) packages for input/output handling and logging, respectively. It also relies on several custom classes (**AppConstants**, **DirectoryService**, **FileService**, **Input**, **ScriptService**, and **Validator**) for various tasks.

## Getting Started

Activate globally via:
```sh
dart pub global activate jarvis
```
Pub installs executables into $HOME/.pub-cache/bin
If the one not in your path please add this command to your shell's config file (.bashrc, .bash_profile, etc.)

```sh
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Abailable Commands
We are change the command from `emigma` to `jarvis` for the package name.

Create a new Flutter project with the following command:
```sh
jarvis create
```
![create_readme.gif](doc%2Freadme%2Fcreate_readme.gif)

______________________________________________
Create a new module with the following command:
```sh
jarvis module
```
![create_module.gif](doc%2Freadme%2Fcreate_module.gif)

______________________________________________
Create a new repository with the following command:
```sh
jarvis repository
```
![create_repo.gif](doc%2Freadme%2Fcreate_repo.gif)

______________________________________________
Create a new use case with the following command:
```sh
jarvis usecase
```
![create_usecase.gif](doc%2Freadme%2Fcreate_usecase.gif)

______________________________________________
Create a new entity (with mapper and model) with the following command:
```sh
jarvis entity
```
![create_entity.gif](doc%2Freadme%2Fcreate_entity.gif)

______________________________________________

## Plugins

Dillinger is currently extended with the following plugins.
Instructions on how to use them in your own application are linked below.

| Plugin | README |
| ------ | ------ |
| dcli | https://pub.dev/packages/dcli |
| mason_logger | https://pub.dev/packages/mason_logger |
| args | https://pub.dev/packages/args |


