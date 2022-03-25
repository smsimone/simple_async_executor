import 'package:simple_async_executor/src/executors/i_executor.dart';
import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:simple_async_executor/src/tasks/tasks.dart';

/// Class that runs the [AsyncTask]s in a random order
class BaseExecutor<I, O> extends Executor<AsyncTask<I, O>, I, O> {
  /// Class that runs the [AsyncTask]s in a random order
  ///
  /// [initialTasks] are the initial tasks for the [BaseExecutor]
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  BaseExecutor({
    List<AsyncTask<I, O>>? initialTasks,
    int maxConcurrentTasks = 1,
  })  : assert(
          initialTasks == null ||
              initialTasks.map((t) => t.id).toSet().length ==
                  initialTasks.length,
        ),
        tasks = initialTasks ?? [],
        semaphore = Semaphore(maxConcurrentTasks);

  @override
  final List<AsyncTask<I, O>> tasks;
  @override
  final Semaphore semaphore;
}
