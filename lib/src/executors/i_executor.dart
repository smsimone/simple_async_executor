import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:simple_async_executor/src/executors/base_executor.dart';
import 'package:simple_async_executor/src/executors/priority_executor.dart';
import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:simple_async_executor/src/tasks/tasks.dart';

/// Interface of an AsyncExecutor
///
/// [I] - Input type
/// [O] - Output type
///
/// To use the [Executor] you have to instantiate:
/// - [BaseExecutor] which uses a normal FIFO queue
/// - [PriorityExecutor] which use a [HeapPriorityQueue] to store the
///   [PriorityTask]s that has to be run
abstract class Executor<T extends AsyncTask<I, O>, I, O> {
  List<T> get tasks;

  Semaphore get semaphore;

  /// Executes a single [taskId] and returns the [Future] that will complete
  /// when the task is finished
  Future<O?> executeWithResult(int taskId) {
    execute(taskId);
    return getResult(taskId);
  }

  /// Adds a new [AsyncTask] to the [BaseExecutor]
  ///
  /// [task] is the [AsyncTask] to be added
  /// [execute] is a [bool] that specifies if the task should be executed
  /// immediately or not
  void addTask(T task, {int? index, bool execute = false}) {
    assert(!tasks.any((t) => t.id == task.id));
    _completers[task.id] = Completer<O>();

    if (index != null) {
      tasks.insert(index, task);
    } else {
      tasks.add(task);
    }

    if (execute) _execute(task.id);
  }

  /// Map of [Completer]s that are waiting for a task to be finished
  final _completers = <int, Completer<O?>>{};

  /// Executes a single [taskId]
  @mustCallSuper
  void execute(int taskId) => _execute(taskId);

  /// Returns the [Future] that will complete when the task of [id] is finished
  @mustCallSuper
  Future<O?> getResult(int taskId) {
    assert(_completers.containsKey(taskId));
    return _completers[taskId]!.future;
  }

  /// Executes all the [AsyncTask]s defined in the constructor with
  /// the [_maxConcurrentTasks] parameter specified
  @mustCallSuper
  void executeAll() {
    for (final task in tasks) {
      _execute(task.id);
    }
  }

  void _execute(int taskId) {
    assert(tasks.any((t) => t.id == taskId));
    _completers.putIfAbsent(taskId, () => Completer<O?>());
    final element = tasks.firstWhere((t) => t.id == taskId);
    semaphore.addToQueue(
      () async {
        final res = await element.task(element.input);
        _completers[element.id]!.complete(res);
      },
      taskId,
    );
  }

  /// Returns the number of tasks that are currently running
  int get runningTasks => semaphore.runningTasks;

  /// Returns the number of tasks that are currently waiting
  int get waitingTasks => semaphore.waitingTasks;
}
