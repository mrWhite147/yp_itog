class Validators {
  static String? required(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }

  static String? positiveNumber(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final number = double.tryParse(value.toString().replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'Введите положительное число';
    }
    return null;
  }

  static String? Function(dynamic) combine(List<String? Function(dynamic)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  static String? positiveInteger(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final str = value.toString().trim();
    
    if (str.startsWith('0') && str.length > 1) {
      return 'Число не должно начинаться с нуля';
    }
    if (!RegExp(r'^\d+$').hasMatch(str)) {
      return 'Введите целое число';
    }
    return null;
  }
}