/// Callback for an [AsyncTask]
///
/// [O] - Output type
typedef AsyncTaskCallback<O> = Future<O?> Function();

/// Class that represents a task that must be executed
///
/// [O] - Output type
class AsyncTask<O> {
  AsyncTask(this.id, this.task);

  /// The id that will let you to get the result
  /// of this [AsyncTask]
  final int id;

  final AsyncTaskCallback<O> task;

  @override
  String toString() => 'AsyncTask{id: $id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncTask<O> &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
