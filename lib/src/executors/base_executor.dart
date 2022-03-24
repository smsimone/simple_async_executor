import 'dart:async';

import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:simple_async_executor/src/tasks/tasks.dart';

/// Class that runs the [AsyncTask]s in a random order
class BaseExecutor<I, O> {
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
        _tasks = initialTasks ?? <AsyncTask<I, O>>[],
        _semaphore = Semaphore(maxConcurrentTasks) {
    for (final t in _tasks) {
      _completers[t.id] = Completer<O>();
    }
  }

  /// The tasks the [BaseExecutor] has to run
  final List<AsyncTask<I, O>> _tasks;

  /// The semaphore that helps to ensure that only a certain amount of tasks
  /// will be run at the same time
  final Semaphore _semaphore;

  /// Map of [Completer]s that are waiting for a task to be finished
  final _completers = <int, Completer<O?>>{};

  /// Returns the [Future] that will complete when the task of [id] is finished
  Future<O?> getResult(int id) => _completers[id]!.future;

  /// Adds a new [AsyncTask] to the [BaseExecutor]
  ///
  /// [task] is the [AsyncTask] to be added
  /// [execute] is a [bool] that specifies if the task should be executed
  /// immediately or not
  void addTask(
    AsyncTask<I, O> task, {
    int? index,
    bool execute = false,
  }) {
    assert(!_tasks.any((t) => t.id == task.id));
    _completers[task.id] = Completer<O>();

    if (index != null) {
      _tasks.insert(index, task);
    } else {
      _tasks.add(task);
    }

    if (execute) _execute(task.id);
  }

  /// Executes a single [taskId] and returns the [Future] that will complete
  /// when the task is finished
  Future<O?> executeWithResult(int taskId) {
    _execute(taskId);
    return getResult(taskId);
  }

  /// Executes a single [taskId]
  void execute(int taskId) => _execute(taskId);

  /// Executes all the [AsyncTask]s defined in the constructor with
  /// the [_maxConcurrentTasks] parameter specified
  void executeAll() => _tasks.map((t) => t.id).forEach(_execute);

  /// Executes a single task
  void _execute(int taskId) {
    final element = _tasks.firstWhere((t) => t.id == taskId);
    _semaphore.addToQueue(() async {
      final res = await element.task(element.input);
      _completers[element.id]!.complete(res);
    });
  }

  /// Returns the number of tasks that are currently running
  int get runningTasks => _semaphore.runningTasks;

  /// Returns the number of tasks that are currently waiting
  int get waitingTasks => _semaphore.waitingTasks;
}
