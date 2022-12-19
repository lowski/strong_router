import 'package:flutter/widgets.dart';

import 'routed.dart';

typedef RouteableBuilder = Widget Function(BuildContext context, Routed routed);

abstract class Routeable {
  /// The path of the route (e.g. /account).
  ///
  /// The path can contain parameters, which are defined by a colon (:) followed
  /// by the parameter name. The parameter name can be any string, but it must
  /// not contain a slash (/).
  String get path;

  /// A map that defines how to parse the parameters from the path.
  ///
  /// The key of the map is the parameter name, the value is a function that
  /// takes the parameter value as a string and returns the parsed value.
  Map<String, Object? Function(String value)>? get parameterParser;

  /// The builder that is used to build the widget for this route.
  RouteableBuilder get builder;

  @protected
  Routeable.empty();

  factory Routeable({
    required String path,
    required RouteableBuilder builder,
    Map<String, Object? Function(String value)>? parameterParser,
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
      parameters?.keys.every((key) => path.contains(':$key')) ?? true,
      'Unknown parameter for path: $path',
    );

    for (final parameter in (parameters ?? <String, Object?>{}).entries) {
      if (parameter.value is String) {
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

  bool matches(String path) {
    final uriSegments = Uri.parse(path).pathSegments;
    final pathSegments = this.path.split('/').where((e) => e.isNotEmpty);

    for (var i = 0; i < pathSegments.length; i++) {
      final pathSegment = pathSegments.elementAt(i);
      final uriSegment = uriSegments[i];

      if (pathSegment.startsWith(':')) {
        continue;
      } else if (pathSegment != uriSegment) {
        return false;
      }
    }
    return true;
  }
}

class _Routeable extends Routeable {
  /// The path of the route (e.g. /account).
  ///
  /// The path can contain parameters, which are defined by a colon (:) followed
  /// by the parameter name. The parameter name can be any string, but it must
  /// not contain a slash (/).
  @override
  final String path;

  /// A map that defines how to parse the parameters from the path.
  ///
  /// The key of the map is the parameter name, the value is a function that
  /// takes the parameter value as a string and returns the parsed value.
  @override
  final Map<String, Object? Function(String value)>? parameterParser;

  /// The builder that is used to build the widget for this route.
  @override
  final RouteableBuilder builder;

  _Routeable({
    required this.path,
    required this.builder,
    this.parameterParser,
  })  : assert(!path.contains(':') || parameterParser != null,
            'Parameter parser required for path: $path'),
        assert(
            path.split('/').where((e) => e.isNotEmpty).every(
                  (element) =>
                      !element.startsWith(':') ||
                      parameterParser!.containsKey(element.substring(1)),
                ),
            'Missing parameter parser for path: $path'),
        super.empty();
}
