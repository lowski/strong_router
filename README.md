# StrongRouter

A strongly typed router.

## Quick Start

Add route annotation to your widget and add the auto-generated part:

```dart
part 'my_widget.g.dart';

@StrongRoute('/my-widget')
class MyWidget extends StatelessWidget {
    static const route = _MyWidgetRoute();
    // ...
}
```

Add a `StrongRouter` to your app and configure the `onGenerateRoute` of your `MaterialApp`:

```dart
final StrongRouter router = StrongRouter(
    routeables: [
        MyWidget.route,
    ],
);

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            // ...
            onGenerateRoute: router.generateRoute,
        );
    }
}
```

Run the code generation:

```sh
flutter pub run build_runner
```

## Routes

### Parameters

The `StrongRoute` annotation has support for route parameters. For every parameter you need to specify a parsing function to turn the string into a useful object:

```dart
Order getOrder(String param) => OrderRepository.get(param);

@StrongRoute(
    '/account/order/:order',
    parameterParser: {
        'order': getOrder,
    }
)
class OrderScreen extends StatelessWidget {
    static const route = _OrderScreenRoute();

    OrderScreen({
        Key? key,
        Order order,
    }) : super(key: key);

    // ...
}
```

This will lead to the `getOrder` function being called, when the route is accessed. The return value of the function will be passed to the Widget.

Note: Unfortunately due to the way annotations work in dart you can only pass a declared function in `parameterParser`. An inline function does not work as it is not a constant value.

### Navigating within the App

The main advantage is to provide a standardized strongly-typed way to navigate within the app. This is accesses through a `Route`. There are two ways of pushing a screen to the navigator: `push` and `pushPath`.

`push` is the method which you can use if you already have the objects that are used in the parameters. This function however is strongly-typed through the code-generation so there is no messing around with the `arguments` from a `MaterialRoute`. In the `OrderScreen` example it would look like this:

```dart
openOrderScreen(Order order) {
    return OrderScreen.route.push(
        order: order,
    );
}
```

When using `pushPath` you will go through the extra parameter parsing function. This is useful if you want only one consistent way to access your routes (always through the string path). Here, all arguments are Strings and turned into the object through `parameterParser`. In the `OrderScreen` example it would look like this:

```dart
openOrderScreen(String orderId) {
    return OrderScreen.route.pushPath(
        order: orderId,
    );
}
```

### Working with `Future`

Often loading a parameter is now synchronous. For example you might need to access an external database if you want to load order information. In that case you can use `FutureStrongRoute` to create a route, where the annotated widget is only shown, once all `Future`s are resolved. While the future is still loading a loading widget is built. This `loadingWidget` can be any `Widget`, but can not have any parameters in the constructor. You may also specify an `errorWidget` which will be built in case the `Future` throws an exception. If no `errorWidget` is specified, the exception will not be caught and propagate normally.

```dart
Future<Order> getOrder(String param) => OrderRepository.load(param);

@FutureStrongRoute(
    '/account/orders/:order',
    parameterParser: {
        'order': getOrder,
    },
    loadingWidget: _LoadingScreen,
    errorWidget: _ErrorScreen,
)
class OrderScreen extends StatelessWidget {
    static const route = _OrderScreenRoute();

    OrderScreen({
        Key? key,
        Order order,
    }) : super(key: key);

    // ...
}
```

Note: In the case of a `FutureStrongRoute` the `push` method still takes the return type of the parameter parser function as an argument. However, you may already have an instance of the object you want to show. In that case, it is recommended to pass a `Future.value`, which will resolve immediately and not cause the `loadingWidget` to be shown.

## Strong Typing

There is as much strong typing as possible in this package. This leads to almost all possible type errors being found at compile time.

The return type of a function in `parameterParser` is checked against the argument type in the widget constructor. They must match exactly otherwise the build runner will not run. For a `FutureStrongRoute` the argument must match the generic type (`T`) of the `Future<T>`. This means that you cannot mix and match between `Future` and `T`. With `@FutureStrongRoute` you cannot pass a `Future<T>` to the Widget constructor.

The build runner will also throw an error, if the `loadingWidget` or `errorWidget` are not a `Widget`.
