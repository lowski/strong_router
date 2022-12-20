import 'dart:async';

import 'package:flutter/widgets.dart';

import 'routeable.dart';
import 'routed.dart';

class AsyncRouteable extends Routeable {
  @override
  final String path;
  @override
  final List<String>? alternativePaths;

  @override
  RouteableBuilder get builder => _asyncBuilder;

  @override
  final Map<String, FutureOr<Object?>? Function(String value)>? parameterParser;

  final RouteableBuilder _loadedBuilder;
  final RouteableBuilder loadingBuilder;
  final RouteableBuilder? errorBuilder;

  Widget _asyncBuilder(BuildContext context, Routed routed) {
    if (!routed.hasFutureParameters) {
      return _loadedBuilder(context, routed);
    }

    return FutureBuilder<Routed>(
      future: routed.completeFutures(),
      builder: (context, snapshot) =>
          snapshot.connectionState != ConnectionState.done
              ? loadingBuilder(context, routed)
              : snapshot.hasError && errorBuilder != null
                  ? errorBuilder!(context, routed)
                  : _loadedBuilder(context, snapshot.requireData),
    );
  }

  const AsyncRouteable({
    required this.path,
    required RouteableBuilder builder,
    required this.loadingBuilder,
    required this.parameterParser,
    this.errorBuilder,
    this.alternativePaths,
  })  : _loadedBuilder = builder,
        super.empty();
}
