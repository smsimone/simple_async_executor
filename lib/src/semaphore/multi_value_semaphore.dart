import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:simple_async_executor/src/extensions/value_notifier_extension.dart';
import 'package:simple_async_executor/src/semaphore/pool.dart';

/// Posix-like semaphore implementation.
class Semaphore {
  /// Posix-like semaphore implementation.
  ///
  /// [waitingQueue] specifies the [Queue] implementation for the waiting queue.
  Semaphore(
    this._maxPermits, {
    SemaphorePool<Function>? waitingQueue,
  })  : _permits = ValueNotifier(0),
        _waiting = waitingQueue ?? BasicPool<Function>() {
    _permits.addListener(_onPermitsChanged);
  }

  /// Max number of [_permits] for the current [Semaphore]
  final int _maxPermits;

  /// Queue of waiting tasks.
  final SemaphorePool<Function> _waiting;

  /// Queue of running tasks
  final _running = ListQueue<Function>();

  /// Number of permits allowed at the same time
  ///
  /// Will be set to [_maxPermits] when the [Semaphore] is started.
  final ValueNotifier<int> _permits;

  /// Number of waiting tasks
  int get waitingTasks => _waiting.length;

  /// Number of running tasks
  int get runningTasks => _running.length;

  /// Returns the [SemaphorePool] that is used to store the waiting tasks.
  SemaphorePool<Function> get waitingPool => _waiting;

  /// Increments the number of the [_permits] by one.
  void _post() => _permits.increment();

  /// Decrements the number of [_permits] by one.
  ///
  /// If none is available, waits until one is available.
  ///
  /// [function] is the function to be executed when the semaphore is available.
  Future<void> addToQueue(Function function, [int? id]) async =>
      _waiting.add(function, id);

  /// Starts the [Semaphore] and executes all waiting tasks.
  void start() {
    assert(_permits.value == 0);
    _permits.value = _maxPermits;
  }

  /// Listener for [_permits].
  ///
  /// This will be called when the number of [_permits] changes
  void _onPermitsChanged() {
    if (_waiting.isEmpty) {
      return;
    }
    _executeNext();
    if (_permits.value > 0) _permits.decrement();
  }

  /// Removes the first task from the waiting queue and executes it.
  void _executeNext() {
    final function = _waiting.removeFirst();
    _running.add(function);
    final res = function();
    if (res is Future) {
      res.then((value) {
        _post();
        _running.remove(function);
      });
    } else {
      _post();
      _running.remove(function);
    }
  }
}
