import 'dart:collection';

import 'package:collection/collection.dart';

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

  @override
  void add(T element, [int? id]) {
    assert(!_queue.contains(element));
    _queue.add(element);
  }

  @override
  int get length => _queue.length;

  @override
  T removeFirst() => _queue.removeFirst();
}

/// Implementation of [SemaphorePool] using a [PriorityQueue]
class PriorityPool<T, P> extends SemaphorePool<T> {
  PriorityPool(
    Comparator<_PriorityWrapper<P, T>> comparator, {
    required this.defaultPriority,
  }) : _queue = PriorityQueue<_PriorityWrapper<P, T>>(comparator);

  late final PriorityQueue<_PriorityWrapper<P, T>> _queue;

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
  T removeFirst() => _queue.removeFirst().element;

  /// Changes the priority of the single element that matches the [selector]
  void changePriority(bool Function(int itemId) selector, P priority) {
    assert(
      _queue.toList().where((element) => selector(element.id)).length == 1,
      'The selector must match only one item',
    );

    final tempItems = _queue.toList();

    tempItems.singleWhere((item) => selector(item.id)).priority = priority;

    _queue
      ..clear()
      ..addAll(tempItems);

    assert(
      _queue.toList().singleWhere((item) => selector(item.id)).priority ==
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
      '_PriorityWrapper{priority: $priority, element: $element}';
}
