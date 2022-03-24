import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:simple_async_executor/src/extensions/value_notifier_extension.dart';

/// Posix-like semaphore implementation.
class Semaphore {
  /// Posix-like semaphore implementation.
  ///
  /// [waitingQueue] specifies the [Queue] implementation for the waiting queue.
  Semaphore(
    int permits, {
    Queue<Function>? waitingQueue,
  })  : permits = ValueNotifier(permits),
        _waiting = waitingQueue ?? ListQueue<Function>() {
    this.permits.addListener(_onPermitsChanged);
  }

  /// Queue of waiting tasks.
  final Queue<Function> _waiting;

  /// Queue of running tasks
  final _running = ListQueue<Function>();

  /// Number of permits allowed at the same time
  final ValueNotifier<int> permits;

  /// Number of waiting tasks
  int get waitingTasks => _waiting.length;

  /// Number of running tasks
  int get runningTasks => _running.length;

  /// Increments the number of the [permits] by one.
  void _post() => permits.increment();

  /// Decrements the number of [permits] by one.
  ///
  /// If none is available, waits until one is available.
  ///
  /// [function] is the function to be executed when the semaphore is available.
  Future<void> addToQueue(Function function) async {
    if (permits.value > 0) {
      permits.decrement();
      _run(function);
      return;
    }

    _waiting.add(function);
  }

  /// Listener for [permits].
  ///
  /// This will be called when the number of [permits] changes
  void _onPermitsChanged() {
    if (_waiting.isEmpty) {
      return;
    }

    final function = _waiting.removeFirst();
    _run(function);
  }

  void _run(Function function) {
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
