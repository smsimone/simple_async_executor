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
abstract class Executor<O> {
  Executor() {
    registerTasks();
    _registerListener();
  }

  List<AsyncTask<O>> get tasks;

  Semaphore get semaphore;

  /// Map of [Completer]s that are waiting for a task to be finished
  final _completers = <int, Completer<O?>>{};

  /// Map of results of the completed [_completers]
  final _results = <int, O?>{};

  /// Flag that indicates if the executor is disposed or not
  var _isClosed = false;

  /// Returns `true` if the semaphore has some running tasks or some
  /// waiting tasks
  bool get isRunning =>
      semaphore.isRunning && _completers.values.any((e) => !e.isCompleted);

  /// Returns `true` if the [Executor] has finished all its jobs
  bool get isDone =>
      semaphore.isRunning &&
      _completers.values.every((element) => element.isCompleted);

  /// Returns the number of tasks that are currently running
  int get runningTasks => semaphore.runningTasks;

  /// Returns the number of tasks that are currently waiting
  int get waitingTasks => semaphore.waitingTasks;

  /// Returns when all the tasks are done
  Future<void> get waitUntilDone =>
      Future.wait(_completers.values.map((c) => c.future));

  /// Registers the listener on [semaphore] to receive the completed
  /// tasks and their results
  void _registerListener() {
    semaphore.onTaskCompleted().listen((event) {
      assert(_completers[event.key] != null);
      assert(!_completers[event.key]!.isCompleted);
      _completers[event.key]!.complete(event.value as O?);
      _results[event.key] = event.value as O?;
    });
  }

  /// Adds a new [AsyncTask] to the [BaseExecutor]
  ///
  /// [task] is the [AsyncTask] to be added
  void addTask(AsyncTask<O> task) {
    assert(!tasks.any((t) => t.id == task.id));
    _completers[task.id] = Completer<O>();
    tasks.add(task);
    debugPrint('Adding task ${task.id} in queue');
    _addToQueue(task.id);
  }

  @protected
  void registerTasks() => tasks.map((t) => t.id).forEach(_addToQueue);

  /// Closes all the running [AsyncTask]s and disposes the [Executor]
  void dispose() {
    _isClosed = true;
    semaphore.dispose();
  }

  /// Returns the [Future] that will complete when the task of [id] is finished
  @mustCallSuper
  Future<O?> getResult(int taskId) {
    assert(_completers.containsKey(taskId));
    final completer = _completers[taskId]!;
    if (completer.isCompleted) {
      debugPrint('Task $taskId was already completed');
      assert(_results[taskId] != null);
      return Future.value(_results[taskId]);
    }
    return _completers[taskId]!.future;
  }

  /// Executes all the [AsyncTask]s defined in the constructor with
  /// the [_maxConcurrentTasks] parameter specified
  @mustCallSuper
  void start() {
    assert(semaphore.waitingTasks > 0);
    assert(!isRunning);
    semaphore.start();
  }

  void _addToQueue(int taskId) {
    assert(tasks.any((t) => t.id == taskId));
    _completers.putIfAbsent(taskId, () => Completer<O?>());
    final element = tasks.firstWhere((t) => t.id == taskId);
    int? priority =
        element is PriorityTask ? (element as PriorityTask).priority : null;
    semaphore.addToQueue(element.task, taskId, priority);
    debugPrint('Added task $taskId in queue');
  }
}
