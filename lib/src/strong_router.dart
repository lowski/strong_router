import 'package:flutter/material.dart';

import 'debug.dart';
import 'routeable.dart';
import 'routed.dart';

class StrongRouter {
  final List<Routeable> routeables;

  const StrongRouter({
    required this.routeables,
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
