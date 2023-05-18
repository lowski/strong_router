import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

/// Generate a method that can be used to push a routeable to the navigator
/// using the [Routeable.pushTo] method. The following values of the method are
/// set: return type (`Future<T?>?`), parameters (`BuildContext`, additional
/// passed parameters), body (`routeable.pushTo`; see example).
///
/// [parameterReturnTypeMap] is a map of the return type as a String for every
/// parameter of the function.
///
/// Example:
/// ```dart
/// // Input
/// _generateRouteablePushToProxy(
///   b,
///   parameterReturnTypeMap: { 'order': 'Future<Cart?>' },
/// );
///
/// // Output
/// Future<T?>? push<T extends Object?>(
///   BuildContext context, {
///   required Future<Cart?> order,
/// }) {
///   return routeable.pushTo<T>(context, { 'order': order });
/// }
/// ```
void _generateRouteablePushToProxy(
  MethodBuilder b, {
  required Map<String, String> parameterReturnTypeMap,
}) {
  b.returns = refer('Future<T?>?');
  b.types.add(refer('T extends Object?'));
  b.requiredParameters.add(
    Parameter((b) => b
      ..name = 'context'
      ..type = refer('BuildContext')),
  );

  for (final entry in parameterReturnTypeMap.entries) {
    b.optionalParameters.add(
      Parameter((b) => b
        ..name = entry.key
        ..required = true
        ..named = true
        ..type = refer(entry.value)),
    );
  }

  final pushToArguments =
      parameterReturnTypeMap.keys.map((e) => "'$e': $e").join(', \n');

  if (pushToArguments.isEmpty) {
    b.body = const Code('return routeable.pushTo<T>(context, {});');
  } else {
    b.body = Code('''
            return routeable.pushTo<T>(
              context,
              {
                $pushToArguments,
              }
            );''');
  }
}

void generatePushMethod(
  ClassBuilder b, {
  required Map<String, DartType> returnTypePerParameter,
  bool replaceFuture = false,
}) {
  b.methods.add(Method((b) {
    b.name = 'push';

    _generateRouteablePushToProxy(
      b,
      parameterReturnTypeMap: returnTypePerParameter.map(
        (key, value) {
          return MapEntry(
            key,
            value
                .getDisplayString(withNullability: true)
                .replaceAll('Future', replaceFuture ? 'FutureOr' : 'Future'),
          );
        },
      ),
    );
  }));
}

void generatePushPathMethod(
  ClassBuilder b, {
  required Map<String, DartType> returnTypePerParameter,
}) {
  b.methods.add(Method((b) {
    b.name = 'pushPath';

    _generateRouteablePushToProxy(
      b,
      parameterReturnTypeMap: returnTypePerParameter.map(
        (key, value) => MapEntry(key, 'String'),
      ),
    );
  }));
}

void generateRouteableProxyMethods(ClassBuilder b) {
  b.methods.add(Method((b) {
    b.name = 'pushTo';
    b.returns = refer('Future<T?>');
    b.types.add(refer('T extends Object?'));
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));
    b.requiredParameters.add(
      Parameter((b) => b
        ..name = 'context'
        ..type = refer('BuildContext')),
    );
    b.optionalParameters.add(
      Parameter((b) => b
        ..name = 'parameters'
        ..type = refer('Map<String, dynamic>?')),
    );
    b.body = const Code('routeable.pushTo(context, parameters)');
  }));

  b.methods.add(Method((b) {
    b.name = 'builder';
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = const Code('routeable.builder');
  }));

  b.methods.add(Method((b) {
    b.name = 'path';
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = const Code('routeable.path');
  }));

  b.methods.add(Method((b) {
    b.name = 'alternativePaths';
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = const Code('routeable.alternativePaths');
  }));
  b.methods.add(Method((b) {
    b.name = 'additionalParameters';
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = const Code('routeable.additionalParameters');
  }));

  b.methods.add(Method((b) {
    b.name = 'parameterParser';
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = const Code('routeable.parameterParser');
  }));

  b.methods.add(Method((b) {
    b.name = 'matches';
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.requiredParameters.add(
      Parameter((b) => b
        ..name = 'path'
        ..type = refer('String')),
    );
    b.body = const Code('routeable.matches(path)');
  }));
  b.methods.add(Method((b) {
    b.name = 'getMatchedPath';
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.requiredParameters.add(
      Parameter((b) => b
        ..name = 'path'
        ..type = refer('String')),
    );
    b.body = const Code('routeable.getMatchedPath(path)');
  }));
}
