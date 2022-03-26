import 'package:simple_async_executor/simple_async_executor.dart';

/// A task that includes also a value [P] of priority to reorganize
/// the tasks in runtime
class PriorityTask<I, O> extends AsyncTask<I, O> {
  PriorityTask(
    int id,
    AsyncTaskCallback<I, O> task,
    this.priority, [
    I? input,
  ]) : super(id, task, input);

  final int priority;

  @override
  String toString() => 'PriorityTask{id: $id, input: $input}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityTask<I, O> &&
          runtimeType == other.runtimeType &&
          super == other;

  @override
  int get hashCode => super.hashCode ^ priority.hashCode;
}
