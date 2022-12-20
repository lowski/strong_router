import 'base_route.dart';

class StrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;
  final List<String>? alternativePaths;

  const StrongRoute(
    this.path, {
    this.parameterParser,
    this.alternativePaths,
  });
}

class FutureStrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;
  final Type loadingWidget;
  final Type? errorWidget;
  final List<String>? alternativePaths;

  const FutureStrongRoute({
    required this.path,
    required this.loadingWidget,
    this.errorWidget,
    this.parameterParser,
    this.alternativePaths,
  });
}
