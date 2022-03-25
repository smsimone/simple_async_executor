# Simple async executor

This packages provides a simple API to handle asynchronous tasks.
Currently it supports only sequential execution, but in next releases it will be extended to support also priority queues.

## Usage

To use this package you need to import it:

```dart
import 'package:simple_async_executor/simple_async_executor.dart';
```

and then build your executor:

```dart
final executor = BaseExecutor<void, void>(
    initialTasks: [
        AsyncTask(1, (_) async {
            // do something
        }),
        AsyncTask(2, (_) async {
            // do something
        }),
    ],
    maxConcurrentTasks: 3,
);
```

and then run the tasks defined:

```dart
executor.executeAll();

/// Gets the result of the [AsyncTask] with the given id
final result = await executor.getResult(1);
```
