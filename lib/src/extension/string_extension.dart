extension StringExtension on String? {
  bool toBool() {
    switch (this) {
      case 'true':
        return true;
      case 'yes':
        return true;
      case 'no':
        return false;
      case 'false':
        return false;
      default:
        return false;
    }
  }
}
