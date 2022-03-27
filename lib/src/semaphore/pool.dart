import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:simple_async_executor/src/semaphore/function_wrapper.dart';

abstract class SemaphorePool<T> {
  /// Returns the amount of elements in the pool
  int get length;

  /// Returns true `true` if the pool is empty
  bool get isEmpty => length == 0;

  /// Insert an element in the pool
  ///
  /// If the [id] is required (as in the case of [PriorityPool]) but it's not
  /// defined, it will be the [element]s hashCode
  void add(AsyncFunction<T> element, int id, [int? priority]);

  /// Remove the first element from the pool
  FunctionWrapper<T> removeFirst();

  /// Returns the items contained in the [SemaphorePool]
  ///
  /// In case of a [BasicPool], the [_PriorityWrapper] items will all have
  /// a [FunctionWrapper.id] of `-1` and a [PriorityElementWrapper.priority] of `0`
  List<FunctionWrapper<T>> get items;

  /// Removes all the items in the [SemaphorePool]
  void clear();
}

/// Basic implementation with of [SemaphorePool] using a [ListQueue]
class BasicPool<T> extends SemaphorePool<T> {
  final _queue = ListQueue<FunctionWrapper<T>>();

  final _executed = ListQueue<FunctionWrapper<T>>();

  @override
  void add(AsyncFunction<T> element, int id, [int? priority]) {
    assert(_queue.none((p0) => p0.id == id));

    _queue.add(FunctionWrapper(id, element));
  }

  @override
  int get length => _queue.length;

  @override
  FunctionWrapper<T> removeFirst() {
    assert(_queue.isNotEmpty);
    final item = _queue.removeFirst();
    _executed.add(item);
    return item;
  }

  @override
  List<FunctionWrapper<T>> get items => _queue.toList();

  @override
  void clear() => _queue.clear();
}

/// Implementation of [SemaphorePool] using a [PriorityQueue]
class PriorityPool<T> extends SemaphorePool<T> {
  PriorityPool(
    Comparator<PriorityElementWrapper<T>> comparator, {
    this.defaultPriority = 0,
  }) : _queue = PriorityQueue<PriorityElementWrapper<T>>(comparator);

  late final PriorityQueue<PriorityElementWrapper<T>> _queue;
  final _executed = ListQueue<int>();

  final int defaultPriority;

  @override
  void add(AsyncFunction<T> element, [int? id, int? priority]) {
    assert(_queue.unorderedElements.none((p0) => p0.id == id));
    _queue.add(
      PriorityElementWrapper<T>(
        id ?? element.hashCode,
        element,
        priority ?? defaultPriority,
      ),
    );
  }

  @override
  int get length => _queue.length;

  @override
  FunctionWrapper<T> removeFirst() {
    assert(_queue.isNotEmpty);
    final element = _queue.removeFirst();
    debugPrint(
      'Removing element with id: ${element.id} and priority: ${element.priority}',
    );
    _executed.add(element.id);
    return element;
  }

  /// Changes the priority of the single element that matches the [selector]
  void changePriority(int itemId, int priority) {
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

  @override
  List<PriorityElementWrapper<T>> get items => _queue.toList();

  @override
  void clear() => _queue.clear();
}
