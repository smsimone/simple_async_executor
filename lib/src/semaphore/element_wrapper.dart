/// Class that wraps an element with its id
class ElementWrapper<T> {
  /// Class that wraps an element with its id
  ElementWrapper(this.id, this.item);

  final int id;
  final T item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementWrapper && item == other.item && id == other.id;

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() => 'ElementWrapper{id: $id, element: $item}';
}

/// Extension of [ElementWrapper] that adds a priority
class PriorityElementWrapper<T> extends ElementWrapper<T> {
  /// Extension of [ElementWrapper] that adds a priority
  PriorityElementWrapper(
    int id,
    T element,
    this.priority,
  ) : super(id, element);

  int priority;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityElementWrapper &&
          item == other.item &&
          id == other.id &&
          priority == other.priority;

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() =>
      'PriorityElementWrapper{id: $id, priority: $priority, element: $item}';
}
