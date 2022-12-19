import 'base_route.dart';

class StrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;

  const StrongRoute(
    this.path, {
    this.parameterParser,
  });
}

class FutureStrongRoute extends BaseRoute {
  final String path;
  final Map<String, Object? Function(String value)>? parameterParser;
  final Type loadingWidget;
  final Type? errorWidget;

  const FutureStrongRoute({
    required this.path,
    required this.loadingWidget,
    this.errorWidget,
    this.parameterParser,
  });
}
