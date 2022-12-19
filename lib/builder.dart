library strong_router.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/builder/routeable_generator.dart';

Builder routeable(BuilderOptions options) {
  return SharedPartBuilder(
    [
      RouteableGenerator(),
    ],
    'routeable',
  );
}
