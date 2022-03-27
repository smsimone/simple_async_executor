typedef AsyncFunction<T> = Future<T> Function();

/// Class that wraps an element with its id
class FunctionWrapper<T> {
  /// Class that wraps an element with its id
  FunctionWrapper(this.id, this.item);

  final int id;
  final AsyncFunction<T> item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionWrapper<T> && item == other.item && id == other.id;

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() => 'ElementWrapper{id: $id, element: $item}';
}

/// Extension of [FunctionWrapper] that adds a priority
class PriorityElementWrapper<T> extends FunctionWrapper<T> {
  /// Extension of [FunctionWrapper] that adds a priority
  PriorityElementWrapper(
    int id,
    AsyncFunction<T> element,
    this.priority,
  ) : super(id, element);

  int priority;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityElementWrapper<T> &&
          item == other.item &&
          id == other.id &&
          priority == other.priority;

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() =>
      'PriorityElementWrapper{id: $id, priority: $priority, element: $item}';
}
