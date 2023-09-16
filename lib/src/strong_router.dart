import 'package:flutter/material.dart';

import 'debug.dart';
import 'routeable.dart';
import 'routed.dart';

/// A router that can parse routes from a URL and build a route from a
/// [Routeable].
///
/// The [buildRoute] function is used to build the route from the resolved
/// [Routed] object. The default implementation uses [MaterialPageRoute]:
///
/// ```dart
/// Route<dynamic> _defaultBuildRoute(
///   Routed routed,
///   RouteableBuilder builder,
/// ) =>
///    MaterialPageRoute(
///      builder: (context) => builder(context, routed),
///      settings: routed.settings,
///    );
/// ```
class StrongRouter {
  final List<Routeable> routeables;

  final Route<dynamic> Function(Routed routed, RouteableBuilder builder)
      buildRoute;

  static Route<dynamic> _defaultBuildRoute(
    Routed routed,
    RouteableBuilder builder,
  ) =>
      MaterialPageRoute(
        builder: (context) => builder(context, routed),
        settings: routed.settings,
      );

  const StrongRouter({
    required this.routeables,
    this.buildRoute = _defaultBuildRoute,
  });

  Routed? parseRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name!);
    Map<String, Object?>? args = {};
    if (settings.arguments is Map) {
      try {
        args = (settings.arguments as Map).cast<String, Object?>();
      } catch (e) {
        lError(
          this,
          'Failed to cast route arguments to Map<String, Object?> for route ${settings.name}',
        );
      }
    }
    final uriSegments = uri.pathSegments;

    for (final routeable in routeables) {
      final paths = [routeable.path, ...routeable.alternativePaths ?? []];

      final segmentLengthMatch = paths.any((p) {
        final pathSegments = p.split('/').where((String e) => e.isNotEmpty);
        return pathSegments.length == uriSegments.length;
      });
      if (!segmentLengthMatch) {
        continue;
      }

      final matchedPath = routeable.getMatchedPath(settings.name!);
      if (matchedPath == null) {
        continue;
      }

      final parameters = <String, Object?>{};
      final pathSegments = matchedPath.split('/').where((e) => e.isNotEmpty);

      // parse the parameters
      for (var i = 0; i < pathSegments.length; i++) {
        final pathSegment = pathSegments.elementAt(i);

        if (!pathSegment.startsWith(':')) {
          continue;
        }

        final uriSegment = uriSegments[i];
        final key = pathSegment.substring(1);

        if (args != null && args.containsKey(key)) {
          parameters[key] = args[key];
          continue;
        }

        final value = routeable.parameterParser![key]!(uriSegment);
        parameters[key] = value;
      }

      for (final key in routeable.additionalParameters ?? []) {
        if (args != null && args.containsKey(key)) {
          parameters[key] = args[key];
        }
      }

      return Routed(
        routeable: routeable,
        parameters: parameters,
        settings: settings,
      );
    }

    return null;
  }

  Route<dynamic> generateRoute(RouteSettings settings) {
    final routed = parseRoute(settings);

    if (routed == null) {
      throw Exception('Invalid route: ${settings.name}');
    }

    return MaterialPageRoute(
      builder: (context) => routed.routeable.builder(context, routed),
      settings: settings,
    );
  }

  List<Route> generateInitialRoutes(
    NavigatorState navigator,
    String initialRoute,
  ) =>
      [
        generateRoute(
          RouteSettings(name: initialRoute),
        ),
      ];
}
