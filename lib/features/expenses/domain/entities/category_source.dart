/// Where an expense category is defined.
enum CategorySource {
  defaultSource('default'),
  custom('custom');

  const CategorySource(this.value);

  final String value;

  static CategorySource fromValue(String? raw) {
    if (raw == custom.value) return custom;
    return defaultSource;
  }
}
