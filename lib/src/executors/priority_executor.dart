import 'package:simple_async_executor/simple_async_executor.dart';
import 'package:simple_async_executor/src/executors/i_executor.dart';
import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:simple_async_executor/src/semaphore/pool.dart';

/// Comparator to sort the [PriorityTask]s by their priority.
typedef PriorityComparator<P> = int Function(P p1, P p2);

/// Creates a [Executor] that handles its waiting queue with a [PriorityPool]
///
/// [I] - Input type of the [PriorityTask]
/// [O] - Output type of the [PriorityTask]
/// [P] - Priority type of the [PriorityTask]
class PriorityExecutor<I, O> extends Executor<PriorityTask<I, O>, I, O> {
  /// Creates a [Executor] that handles its waiting queue with a [PriorityPool]
  ///
  /// [I] - Input type of the [PriorityTask]
  /// [O] - Output type of the [PriorityTask]
  /// [P] - Priority type of the [PriorityTask]
  PriorityExecutor({
    List<PriorityTask<I, O>>? initialTasks,
    int maxConcurrentTasks = 1,
  })  : assert(
          initialTasks == null ||
              initialTasks.map((t) => t.id).toSet().length ==
                  initialTasks.length,
        ),
        tasks = initialTasks ?? [],
        semaphore = Semaphore(
          maxConcurrentTasks,
          waitingQueue: PriorityPool<Function>(
            (p1, p2) => p2.priority.compareTo(p1.priority),
            defaultPriority: 0,
          ),
        ) {
    registerTasks();

    assert(() {
      if (initialTasks == null) {
        return true;
      }
      return semaphore.waitingPool.items.every(
        (pElem) =>
            pElem.priority ==
            initialTasks.firstWhere((qElem) => qElem.id == pElem.id).priority,
      );
    }());
  }

  @override
  final List<PriorityTask<I, O>> tasks;
  @override
  final Semaphore semaphore;

  /// Modifies the priority of the task [taskId]
  void changePriority(int taskId, int priority) {
    assert(tasks.any((t) => t.id == taskId));
    final pool = semaphore.waitingPool;
    assert(pool is PriorityPool);
    final task = tasks.firstWhere((t) => t.id == taskId);
    (pool as PriorityPool<Function>).changePriority(
      task.id,
      priority,
    );
  }

  /// Changes the priority of all tasks contained in [taskIds]
  ///
  /// The map should be in the form of:
  /// ```json
  /// {
  ///   'priorityValue': [taskIds],
  ///   ...
  /// }
  /// ```
  void bulkChangePriority(Map<int, List<int>> taskIds) {
    assert(
      () {
        final ids = taskIds.values.expand((element) => [...element]).toList();
        final currentIds = tasks.map((t) => t.id).toList();

        return ids.every((id) => currentIds.contains(id));
      }(),
      'There are some ids that are not in the tasks list',
    );

    for (final edit in taskIds.entries) {
      final priority = edit.key;
      for (final task in edit.value) {
        changePriority(task, priority);
      }
    }
  }
}
