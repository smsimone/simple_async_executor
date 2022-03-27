import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:simple_async_executor/src/extensions/value_notifier_extension.dart';
import 'package:simple_async_executor/src/semaphore/function_wrapper.dart';
import 'package:simple_async_executor/src/semaphore/pool.dart';

/// Posix-like semaphore implementation.
class Semaphore {
  /// Posix-like semaphore implementation.
  ///
  /// [waitingQueue] specifies the [Queue] implementation for the waiting queue.
  Semaphore(
    this._maxPermits, {
    SemaphorePool? waitingQueue,
  })  : assert(_maxPermits >= 1),
        _permits = ValueNotifier(-1) {
    _waiting = waitingQueue ?? BasicPool();
    _permits.addListener(_onPermitsChanged);
  }

  bool _isRunning = false;

  bool _isDisposed = false;

  /// Flag that specifies is current [Semaphore] is running or not
  ///
  /// This will be changed when [Semaphore.start] is called
  bool get isRunning => _isRunning;

  /// Max number of [_permits] for the current [Semaphore]
  final int _maxPermits;

  /// Queue of waiting tasks.
  late final SemaphorePool _waiting;

  /// Stream on which will be publicated the completed tasks
  final _completedTasksStream =
      StreamController<MapEntry<int, dynamic>>.broadcast();

  /// Map of current running tasks with their [CancelableOperation]
  final _running = <int, CancelableOperation>{};

  /// Counter that keeps the number of completed tasks of the [Semaphore]
  var _tasksCompleted = 0;

  /// Number of permits allowed at the same time
  ///
  /// Will be set to [_maxPermits] when the [Semaphore] is started.
  final ValueNotifier<int> _permits;

  /// Number of waiting tasks
  int get waitingTasks => _waiting.length;

  /// Number of running tasks
  int get runningTasks => _running.length;

  /// Returns the number of completed tasks of the [Semaphore]
  int get completedTasks => _tasksCompleted;

  /// Returns `true` if the semaphore was disposed
  bool get isDisposed {
    assert(!_isDisposed || _running.isEmpty);
    assert(!_isDisposed || _waiting.isEmpty);
    return _isDisposed;
  }

  /// Returns the [SemaphorePool] that is used to store the waiting tasks.
  SemaphorePool get waitingPool => _waiting;

  /// Decrements the number of [_permits] by one.
  ///
  /// If none is available, waits until one is available.
  ///
  /// [function] is the function to be executed when the semaphore is available.
  Future<void> addToQueue(
    AsyncFunction function,
    int id, [
    int? priority,
  ]) async {
    _waiting.add(function, id, priority);
    if (_isRunning) _onPermitsChanged();
  }

  /// Starts the [Semaphore] and executes all waiting tasks.
  void start() {
    assert(!_isRunning);
    assert(_permits.value == -1);
    _isRunning = true;
    _permits.value = _maxPermits;
  }

  /// Disposes the [Semaphore] and closes all the running tasks
  void dispose() {
    _isDisposed = true;
    _running.forEach((key, value) => value.cancel());
    _running.clear();
    _waiting.clear();
  }

  /// Listener for [_permits].
  ///
  /// This will be called when the number of [_permits] changes
  void _onPermitsChanged() {
    assert(_isRunning);
    assert(
      _permits.value >= 0 && _permits.value <= _maxPermits,
      'Current permits value ${_permits.value} is not in range [0, $_maxPermits]',
    );
    if (_waiting.isEmpty || _permits.value == 0) {
      return;
    }
    Future.microtask(_executeNext);
    _permits.decrement();
  }

  /// Increments the number of the [_permits] by one.
  void _post() {
    assert(
      _permits.value < _maxPermits,
      'Current permits value ${_permits.value} is greater than max permits $_maxPermits',
    );
    _permits.increment();
  }

  /// Removes the first task from the waiting queue and executes it.
  Future<void> _executeNext() async {
    assert(_permits.value >= 0);
    assert(_running.length <= _maxPermits);
    if (_waiting.isEmpty) return;
    final element = _waiting.removeFirst();

    debugPrint('Semaphore started task ${element.id}');
    final operation =
        CancelableOperation.fromFuture(element.item()).then((result) {
      _tasksCompleted++;
      _running.remove(element.id);
      _completedTasksStream.sink.add(MapEntry(element.id, result));
      debugPrint('Task ${element.id} has completed');
      _post();
    });
    _running[element.id] = operation;
    assert(_running.length <= _maxPermits);
  }

  /// Returns the [Stream] on which are publicated the completed tasks
  Stream<MapEntry<int, dynamic>> onTaskCompleted() =>
      _completedTasksStream.stream;
}
