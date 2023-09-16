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
    b.name = 'generateRoute';
    b.returns = refer('Route<dynamic>');
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));
    b.requiredParameters.add(
      Parameter((b) => b
        ..name = 'router'
        ..type = refer('StrongRouter')),
    );
    b.optionalParameters.add(
      Parameter((b) => b
        ..name = 'parameters'
        ..type = refer('Map<String, dynamic>?')),
    );
    b.body = const Code('routeable.generateRoute(router, parameters)');
  }));

  _addProxyGetter(b, 'builder');
  _addProxyGetter(b, 'path');
  _addProxyGetter(b, 'alternativePaths');
  _addProxyGetter(b, 'additionalParameters');
  _addProxyGetter(b, 'parameterParser');

  _addProxyMethod(b, 'matches',
      routeableMethodCall: 'matches(path)',
      requiredParameters: {
        'path': 'String',
      });

  _addProxyMethod(b, 'getMatchedPath',
      routeableMethodCall: 'getMatchedPath(path)',
      requiredParameters: {
        'path': 'String',
      });
}

void _addProxyGetter(ClassBuilder b, String name) {
  b.methods.add(Method((b) {
    b.name = name;
    b.type = MethodType.getter;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    b.body = Code('routeable.$name');
  }));
}

void _addProxyMethod(
  ClassBuilder b,
  String name, {
  Map<String, String> requiredParameters = const {},
  Map<String, String> optionalParameters = const {},
  required String routeableMethodCall,
}) {
  b.methods.add(Method((b) {
    b.name = name;
    b.lambda = true;
    b.annotations.add(const CodeExpression(Code('override')));

    for (final entry in requiredParameters.entries) {
      b.requiredParameters.add(
        Parameter((b) => b
          ..name = entry.key
          ..type = refer(entry.value)),
      );
    }

    for (final entry in optionalParameters.entries) {
      b.optionalParameters.add(
        Parameter((b) => b
          ..name = entry.key
          ..type = refer(entry.value)),
      );
    }

    b.body = Code('routeable.$routeableMethodCall');
  }));
}
