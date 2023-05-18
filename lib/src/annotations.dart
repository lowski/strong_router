import 'base_route.dart';

class StrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;
  final List<String>? alternativePaths;
  final List<String>? additionalParameters;

  const StrongRoute(
    this.path, {
    this.parameterParser,
    this.alternativePaths,
    this.additionalParameters,
  });
}

class FutureStrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;
  final Type loadingWidget;
  final Type? errorWidget;
  final List<String>? alternativePaths;
  final List<String>? additionalParameters;

  const FutureStrongRoute({
    required this.path,
    required this.loadingWidget,
    this.errorWidget,
    this.parameterParser,
    this.alternativePaths,
    this.additionalParameters,
  });
}
