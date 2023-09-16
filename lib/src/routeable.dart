import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'routed.dart';

typedef RouteableBuilder = Widget Function(BuildContext context, Routed routed);

abstract class Routeable {
  /// The path of the route (e.g. /account).
  ///
  /// The path can contain parameters, which are defined by a colon (:) followed
  /// by the parameter name. The parameter name can be any string, but it must
  /// not contain a slash (/).
  ///
  /// This is the path that is used if the route is pushed to the navigator. If
  /// you want to use multiple paths for the same route, you can add more paths
  /// with [alternativePaths].
  String get path;

  /// A map that defines how to parse the parameters from the path.
  ///
  /// The key of the map is the parameter name, the value is a function that
  /// takes the parameter value as a string and returns the parsed value.
  Map<String, Object? Function(String value)>? get parameterParser;

  /// The builder that is used to build the widget for this route.
  RouteableBuilder get builder;

  /// Alternative paths of the route (e.g. /account).
  ///
  /// This is useful if you want to have multiple paths for the same route.
  ///
  /// The same rules apply as for [path].
  List<String>? get alternativePaths;

  /// The parameters that are not part of the path.
  ///
  /// This is useful if you want to pass parameters to the route that cannot be
  /// part of the path, e.g. a callback function. They are not parsed from the
  /// path, but passed directly to the route.
  List<String>? get additionalParameters;

  @protected
  const Routeable.empty();

  factory Routeable({
    required String path,
    required RouteableBuilder builder,
    Map<String, Object? Function(String value)>? parameterParser,
    List<String>? alternativePaths,
    List<String>? additionalParameters,
  }) = _Routeable;

  Future<T?> pushTo<T extends Object?>(
    BuildContext context, [
    Map<String, dynamic>? parameters,
  ]) {
    String path = this.path;
    Map<String, Object?>? arguments = {};

    assert(
      !path.contains(':') || parameters != null,
      'Parameters required for path: $path',
    );
    assert(
      path.split('/').where((e) => e.isNotEmpty).every(
            (element) =>
                !element.startsWith(':') ||
                parameters!.containsKey(element.substring(1)),
          ),
      'Missing parameter for path: $path',
    );
    assert(
      parameters?.keys.every((key) =>
              path.contains(':$key') ||
              (additionalParameters?.contains(key) ?? true)) ??
          true,
      'Unknown parameter for path: $path',
    );

    for (final parameter in (parameters ?? <String, Object?>{}).entries) {
      if (parameter.value is String && path.contains(':${parameter.key}')) {
        path = path.replaceFirst(
          ':${parameter.key}',
          parameter.value as String,
        );
      } else {
        arguments[parameter.key] = parameter.value;
      }
    }

    if (arguments.isEmpty) {
      arguments = null;
    }

    return Navigator.of(context).pushNamed(
      path,
      arguments: arguments,
    );
  }

  bool matches(String url) => getMatchedPath(url) != null;

  String? getMatchedPath(String url) {
    final uriSegments = Uri.parse(url).pathSegments;
    final alternativePaths = this.alternativePaths ?? [];
    return [path, ...alternativePaths].firstWhereOrNull((path) {
      final pathSegments = path.split('/').where((e) => e.isNotEmpty);

      for (var i = 0; i < pathSegments.length; i++) {
        final pathSegment = pathSegments.elementAt(i);
        final uriSegment = uriSegments.elementAtOrNull(i);

        if (pathSegment.startsWith(':')) {
          continue;
        } else if (pathSegment != uriSegment) {
          return false;
        }
      }
      return true;
    });
  }
}

class _Routeable extends Routeable {
  @override
  final String path;

  @override
  final List<String>? alternativePaths;

  @override
  final Map<String, Object? Function(String value)>? parameterParser;

  @override
  final RouteableBuilder builder;

  @override
  final List<String>? additionalParameters;

  _Routeable({
    required this.path,
    required this.builder,
    this.parameterParser,
    this.alternativePaths,
    this.additionalParameters,
  })  : assert(!path.contains(':') || parameterParser != null,
            'Parameter parser required for path: $path'),
        assert(
            path.split('/').where((e) => e.isNotEmpty).every(
                  (element) =>
                      !element.startsWith(':') ||
                      parameterParser!.containsKey(element.substring(1)),
                ),
            'Missing parameter parser for path: $path'),
        assert(
          path.split('/').every(
                (element) =>
                    !element.startsWith(':') ||
                    (alternativePaths ?? []).every(
                      (alternativePath) => alternativePath.contains(element),
                    ),
              ),
          'Alternative paths must contain all parameters of the primary path: $path',
        ),
        super.empty();
}
