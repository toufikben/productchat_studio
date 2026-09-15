class Recipe {
  final String id;
  final String name;
  final Map<String, dynamic> steps;

  const Recipe({required this.id, required this.name, this.steps = const {}});
}
