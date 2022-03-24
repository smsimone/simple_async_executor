/// Callback for an [AsyncTask]
///
/// [I] - Input type
/// [O] - Output type
typedef AsyncTaskCallback<I, O> = Future<O?> Function(I? input);

/// Class that represents a task that must be executed
///
/// [I] - Input type
/// [O] - Output type
class AsyncTask<I, O> {
  AsyncTask(this.id, this.task, [this.input]);

  /// The id that will let you to get the result
  /// of this [AsyncTask]
  final int id;

  final AsyncTaskCallback<I, O> task;

  final I? input;

  @override
  String toString() => 'AsyncTask{id: $id, input: $input}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncTask<I, O> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          input == other.input;

  @override
  int get hashCode => id.hashCode ^ input.hashCode;
}
