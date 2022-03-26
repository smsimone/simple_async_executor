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
  })  : assert(_maxPermits >= 1),
        _permits = ValueNotifier(-1),
        _waiting = waitingQueue ?? BasicPool<Function>() {
    _permits.addListener(_onPermitsChanged);
  }

  bool _isRunning = false;

  /// Flag that specifies is current [Semaphore] is running or not
  ///
  /// This will be changed when [Semaphore.start] is called
  bool get isRunning => _isRunning;

  /// Max number of [_permits] for the current [Semaphore]
  final int _maxPermits;

  /// Queue of waiting tasks.
  final SemaphorePool<Function> _waiting;

  /// Queue of running tasks
  final _running = ListQueue<int>();

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

  /// Decrements the number of [_permits] by one.
  ///
  /// If none is available, waits until one is available.
  ///
  /// [function] is the function to be executed when the semaphore is available.
  Future<void> addToQueue(Function function, int id, [int? priority]) async {
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
    _running.add(element.id);
    debugPrint('Semaphore started task ${element.id}');
    final res = element.item();
    if (res is Future) {
      res.then((_) {
        _running.remove(element.id);
        _post();
      });
    } else {
      _running.remove(element.id);
      _post();
    }
  }
}
