import 'package:flutter/widgets.dart';

import 'routed.dart';

/// Return a builder function that will build the widget with the given builder
/// function, but only after all futures in the [Routed] object have completed.
///
/// If the [Routed] object does not contain any futures, the builder function
/// will be called immediately.
///
/// While the futures are loading, the [loadingBuilder] will be called, if
/// provided. Otherwise, a [Scaffold] with an [AnimatedLoader] will be shown.
Widget Function(BuildContext, Routed) routedFutureOrBuilder(
  Widget Function(BuildContext, Routed) builder,
  Widget Function(BuildContext, Routed) loadingBuilder,
) =>
    (context, routed) {
      if (!routed.hasFutureParameters) {
        return builder(context, routed);
      }

      return FutureBuilder<Routed>(
        future: routed.completeFutures(),
        builder: (context, snapshot) =>
            snapshot.connectionState != ConnectionState.done
                ? loadingBuilder(context, routed)
                : builder(context, snapshot.requireData),
      );
    };
