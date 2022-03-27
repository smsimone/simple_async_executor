import 'package:simple_async_executor/src/executors/i_executor.dart';
import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:simple_async_executor/src/tasks/tasks.dart';

/// Class that runs the [AsyncTask]s in a random order
class BaseExecutor<O> extends Executor<O> {
  /// Class that runs the [AsyncTask]s in a random order
  ///
  /// [initialTasks] are the initial tasks for the [BaseExecutor]
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  BaseExecutor({
    List<AsyncTask<O>>? initialTasks,
    int maxConcurrentTasks = 1,
  })  : assert(
          initialTasks == null ||
              initialTasks.map((t) => t.id).toSet().length ==
                  initialTasks.length,
        ),
        tasks = initialTasks ?? [],
        semaphore = Semaphore(maxConcurrentTasks);

  @override
  final List<AsyncTask<O>> tasks;
  @override
  final Semaphore semaphore;
}
