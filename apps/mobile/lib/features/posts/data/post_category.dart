enum PostCategory {
  general('GENERAL', 'General'),
  infrastructure('INFRASTRUCTURE', 'Infrastructure'),
  safety('SAFETY', 'Safety'),
  utilities('UTILITIES', 'Utilities'),
  environment('ENVIRONMENT', 'Environment'),
  other('OTHER', 'Other');

  const PostCategory(this.wireValue, this.label);
  final String wireValue;
  final String label;

  static PostCategory fromWire(String? value) {
    return PostCategory.values.firstWhere(
      (c) => c.wireValue == value,
      orElse: () => PostCategory.general,
    );
  }
}
