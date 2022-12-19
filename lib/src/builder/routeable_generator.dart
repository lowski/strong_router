import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';
import '../base_route.dart';
import 'route_generate_methods.dart';

extension on ClassElement {
  bool isSubclassOf(String className) {
    // recursively check all supertypes if they match className
    for (final type in allSupertypes) {
      if (type.element.name == className) {
        return true;
      }
    }
    for (final type in allSupertypes) {
      if (type.element.kind == ElementKind.CLASS &&
          (type.element as ClassElement).isSubclassOf(className)) {
        return true;
      }
    }

    return false;
  }
}

/// Turns a map into a string of the form "key1: value1, key2: value2, ...".
///
/// If [quoteKeys] is true, the keys will be quoted with single quotes.
///
/// If [quoteValues] is true, the values will be quoted with single quotes.
String argMapToCode(
  Map<String, String> m, {
  bool quoteKeys = false,
  bool quoteValues = false,
  bool trailingComma = true,
}) {
  final keyQuote = quoteKeys ? "'" : '';
  final valueQuote = quoteValues ? "'" : '';

  final result = m.entries
      .map(
          (e) => '$keyQuote${e.key}$keyQuote: $valueQuote${e.value}$valueQuote')
      .join(', ');
  return trailingComma && result.isNotEmpty ? '$result, ' : result;
}

class RouteableGenerator extends GeneratorForAnnotation<BaseRoute> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final routeableName = element.name;
    final path = annotation.read('path').stringValue;
    final routeIsFutureRoute =
        annotation.instanceOf(const TypeChecker.fromRuntime(FutureStrongRoute));

    final mapValue = annotation.read('parameterParser').isNull
        ? {}
        : annotation.read('parameterParser').mapValue;
    final returnTypePerParameter = <String, DartType>{};
    final functionNameByParameter = <String, String>{};

    for (final entry in mapValue.entries) {
      final stringKey = entry.key!.toStringValue()!;
      final val = entry.value!.toFunctionValue()!;
      returnTypePerParameter[stringKey] = val.returnType;
      functionNameByParameter[stringKey] =
          (val.declaration as ExecutableElement).name;
    }

    final defaultConstructor = (element as ClassElement).unnamedConstructor;

    if (defaultConstructor == null) {
      throw InvalidGenerationSourceError(
        'The class $routeableName needs a default constructor (without '
        'parameters) or a constructor with an empty name.',
        element: element,
      );
    }

    final loadingWidget =
        routeIsFutureRoute ? annotation.read('loadingWidget').typeValue : null;
    final errorWidget =
        routeIsFutureRoute ? annotation.peek('errorWidget')?.typeValue : null;

    if (routeIsFutureRoute &&
        (!(loadingWidget!.element! as ClassElement).isSubclassOf('Widget') ||
            (loadingWidget.element! as ClassElement).unnamedConstructor ==
                null)) {
      throw InvalidGenerationSourceError(
        '[loadingWidget] must be a subclass of Widget and have an unnamed constructor.',
        element: element,
      );
    }
    if (routeIsFutureRoute &&
        errorWidget != null &&
        (!(errorWidget.element as ClassElement).isSubclassOf('Widget') ||
            (errorWidget.element as ClassElement).unnamedConstructor == null)) {
      throw InvalidGenerationSourceError(
        '[errorWidget] must be a subclass of Widget and have an unnamed constructor.',
        element: element,
      );
    }

    for (final parameter in defaultConstructor.parameters) {
      if (!parameter.hasDefaultValue &&
          !parameter.isOptional &&
          !returnTypePerParameter.containsKey(parameter.name)) {
        throw InvalidGenerationSourceError(
          'The class $routeableName must have a zero argument constructor or all'
          ' parameters must have a default value or be provided by the route. '
          'Missing parameter: ${parameter.name}',
          element: element,
        );
      }
      if (parameter.isNamed &&
          returnTypePerParameter.containsKey(parameter.name)) {
        final parameterType = parameter.type;
        final returnType = returnTypePerParameter[parameter.name]!;

        if (routeIsFutureRoute &&
            (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr)) {
          final futureGenericType = RegExp(r'Future(?:Or)?<(.+)>')
              .firstMatch(returnType.getDisplayString(withNullability: true))!
              .group(1);

          if (futureGenericType !=
              parameterType.getDisplayString(withNullability: true)) {
            throw InvalidGenerationSourceError(
              'In $routeableName the type of the parameter "${parameter.name}" '
              '(`${parameterType.getDisplayString(withNullability: true)}`) does not'
              ' match the internal Future type of the function in '
              'parameterParser (`$futureGenericType`).',
              element: element,
            );
          }
        } else {
          if (parameterType != returnType) {
            throw InvalidGenerationSourceError(
              'In $routeableName the type of the parameter "${parameter.name}" '
              '(`${parameterType.getDisplayString(withNullability: true)}`) does not'
              ' match the return type of the function in parameterParser '
              '(`${returnType.getDisplayString(withNullability: true)}`).',
              element: element,
            );
          }
        }
      }
    }

    final routeableClass = Class(
      (b) {
        // map the parameter name to its type and only include arguments
        // we actually have a value for
        final constructorArgTypes = <String, DartType>{};
        for (final param in defaultConstructor.parameters) {
          if (!returnTypePerParameter.containsKey(param.name)) continue;

          constructorArgTypes[param.name] = returnTypePerParameter[param.name]!;
        }

        final constructorArgs = <String, String>{};
        for (final entry in constructorArgTypes.entries) {
          final name = entry.key;
          final type = entry.value;

          String typeCast = type.getDisplayString(withNullability: true);

          if (routeIsFutureRoute &&
              (type.isDartAsyncFuture || type.isDartAsyncFutureOr)) {
            typeCast = RegExp(r'Future(?:Or)?<(.+)>')
                .firstMatch(type.getDisplayString(withNullability: true))!
                .group(1)!;
          }
          constructorArgs[name] = 'routed.parameters[\'$name\'] as $typeCast';
        }

        // iff the widget has a const constructor and no arguments, we can use
        // const here
        final builderConstPrefix =
            defaultConstructor.isConst && constructorArgTypes.isEmpty
                ? 'const '
                : '';
        final routeableBuilder = '''
          (context, routed) => $builderConstPrefix $routeableName(
            ${argMapToCode(constructorArgs)}
          )''';

        b.name = '_${routeableName}Route';
        b.implements.add(refer('Routeable'));

        b.fields.add(
          Field(
            (b) {
              b.name = 'routeable';
              b.static = true;
              b.modifier = FieldModifier.final$;

              if (routeIsFutureRoute) {
                final errorWidgetHasConstConstructor = errorWidget != null &&
                    (errorWidget.element as ClassElement)
                        .unnamedConstructor!
                        .isConst;
                final errorWidgetConstPrefix =
                    errorWidgetHasConstConstructor ? 'const ' : '';
                final errorBuilderAssignment = errorWidget == null
                    ? null
                    : '(context, routed) => $errorWidgetConstPrefix ${errorWidget.element!.name}()';

                final loadingWidgetHasConstConstructor =
                    (loadingWidget!.element! as ClassElement)
                        .unnamedConstructor!
                        .isConst;
                final loadingWidgetConstPrefix =
                    loadingWidgetHasConstConstructor ? 'const ' : '';

                b.assignment = Code(
                  '''
                  AsyncRouteable(
                    path: '$path',
                    parameterParser: {
                      ${argMapToCode(functionNameByParameter, quoteKeys: true)}
                    },
                    builder: $routeableBuilder,
                    loadingBuilder: (context, routed) => $loadingWidgetConstPrefix ${loadingWidget.element!.name}(),
                    errorBuilder: $errorBuilderAssignment,
                  )''',
                );
              } else {
                b.assignment = Code(
                  '''
                  Routeable(
                    path: '$path',
                    parameterParser: {
                      ${argMapToCode(functionNameByParameter, quoteKeys: true)}
                    },
                    builder: $routeableBuilder,
                  )''',
                );
              }
            },
          ),
        );

        b.constructors.add(Constructor((b) {
          b.constant = true;
        }));

        generatePushMethod(
          b,
          returnTypePerParameter: returnTypePerParameter,
        );

        generatePushPathMethod(
          b,
          returnTypePerParameter: returnTypePerParameter,
        );

        generateRouteableProxyMethods(b);
      },
    );
    final emitter = DartEmitter(useNullSafetySyntax: true);
    return routeableClass.accept(emitter).toString();
  }
}
