import 'package:simple_async_executor/simple_async_executor.dart';

/// A task that includes also a value of priority to reorganize
/// the tasks in runtime
class PriorityTask<O> extends AsyncTask<O> {
  PriorityTask(
    int id,
    AsyncTaskCallback<O> task,
    this.priority,
  ) : super(id, task);

  final int priority;

  @override
  String toString() => 'PriorityTask{id: $id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityTask<O> &&
          runtimeType == other.runtimeType &&
          super == other;

  @override
  int get hashCode => super.hashCode ^ priority.hashCode;
}
