import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

abstract class SemaphorePool<T> {
  /// Returns the amount of elements in the pool
  int get length;

  /// Returns true `true` if the pool is empty
  bool get isEmpty => length == 0;

  /// Insert an element in the pool
  ///
  /// If the [id] is required (as in the case of [PriorityPool]) but it's not
  /// defined, it will be the [element]s hashCode
  void add(T element, [int? id]);

  /// Remove the first element from the pool
  T removeFirst();
}

/// Basic implementation with of [SemaphorePool] using a [ListQueue]
class BasicPool<T> extends SemaphorePool<T> {
  final _queue = ListQueue<T>();

  final _executed = ListQueue<T>();

  @override
  void add(T element, [int? id]) {
    assert(!_queue.contains(element));
    _queue.add(element);
  }

  @override
  int get length => _queue.length;

  @override
  T removeFirst() {
    final item = _queue.removeFirst();
    _executed.add(item);
    return item;
  }
}

/// Implementation of [SemaphorePool] using a [PriorityQueue]
class PriorityPool<T, P> extends SemaphorePool<T> {
  PriorityPool(
    Comparator<_PriorityWrapper<P, T>> comparator, {
    required this.defaultPriority,
  }) : _queue = PriorityQueue<_PriorityWrapper<P, T>>(comparator);

  late final PriorityQueue<_PriorityWrapper<P, T>> _queue;
  final _executed = ListQueue<int>();

  final P defaultPriority;

  @override
  void add(T element, [int? id]) {
    if (defaultPriority != null) {
      _queue.add(
        _PriorityWrapper(
          id ?? element.hashCode,
          defaultPriority!,
          element,
        ),
      );
    }
  }

  @override
  int get length => _queue.length;

  @override
  T removeFirst() {
    assert(_queue.isNotEmpty);
    final element = _queue.removeFirst();
    _executed.add(element.id);
    return element.element;
  }

  /// Changes the priority of the single element that matches the [selector]
  void changePriority(int itemId, P priority) {
    assert(
      () {
        final itemsFound = [
          ..._queue.toList().map((e) => e.id),
          ..._executed.toList()
        ].where((id) => id == itemId).length;

        if (itemsFound != 1) {
          debugPrint('Found $itemsFound items instead of one');
          return false;
        }
        return true;
      }(),
      'The selector must match exactly one item',
    );

    if (_executed.contains(itemId)) {
      debugPrint('Item $itemId has already been executed');
      return;
    }

    final tempItems = _queue.toList();

    tempItems.singleWhere((item) => item.id == itemId).priority = priority;

    _queue
      ..clear()
      ..addAll(tempItems);

    assert(
      _queue.toList().singleWhere((item) => item.id == itemId).priority ==
          priority,
    );
  }
}

class _PriorityWrapper<P, T> {
  _PriorityWrapper(this.id, this.priority, this.element);

  /// The id that identifies the task to change its priority
  int id;
  P priority;
  final T element;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PriorityWrapper &&
          runtimeType == other.runtimeType &&
          element == other.element;

  @override
  int get hashCode => element.hashCode;

  @override
  String toString() =>
      '_PriorityWrapper{id: $id, priority: $priority, element: $element}';
}
