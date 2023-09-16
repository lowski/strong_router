import 'package:flutter/widgets.dart';

import 'routeable.dart';

class Routed<T extends Routeable> {
  final T routeable;
  final Map<String, Object?> parameters;
  final RouteSettings? settings;

  const Routed({
    required this.routeable,
    required this.parameters,
    required this.settings,
  });

  bool get hasFutureParameters =>
      parameters.values.any((element) => element is Future);

  /// Await all future parameters and return a new [Routed] object where all
  /// parameters are completed.
  Future<Routed<T>> completeFutures() async {
    final resolvedParameters = <String, Object?>{};
    for (final parameter in parameters.entries) {
      if (parameter.value is Future) {
        resolvedParameters[parameter.key] = await (parameter.value as Future);
      } else {
        resolvedParameters[parameter.key] = parameter.value;
      }
    }

    return Routed(
      routeable: routeable,
      parameters: resolvedParameters,
      settings: settings,
    );
  }
}
