import 'package:simple_async_executor/simple_async_executor.dart';
import 'package:test/test.dart';
import 'package:simple_async_executor/src/executors/priority_executor.dart';

void main() {
  group('PriorityExecutor', () {
    test('All items have the same priority', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void, void, int>(
        initialTasks: [
          PriorityTask(0, (_) async => results.add(0), 0),
          PriorityTask(1, (_) async => results.add(1), 0),
          PriorityTask(2, (_) async => results.add(2), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.executeAll();

      await Future.delayed(const Duration(milliseconds: 20));

      expect(results, [0, 1, 2]);
    });

    test('All items have the same priority', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void, void, int>(
        initialTasks: [
          PriorityTask(0, (_) async {
            await Future.delayed(const Duration(milliseconds: 200));
            results.add(0);
          }, 0),
          PriorityTask(1, (_) async {
            await Future.delayed(const Duration(milliseconds: 200));
            results.add(1);
          }, 0),
          PriorityTask(2, (_) async => results.add(2), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.executeAll();

      await Future.delayed(const Duration(milliseconds: 20));

      expect(results, []);
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 1);
    });

    test('Edit priority of one task at runtime', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void, void, int>(
        initialTasks: [
          PriorityTask(0, (_) async {
            await Future.delayed(const Duration(milliseconds: 200));
            results.add(0);
          }, 0),
          PriorityTask(1, (_) async {
            await Future.delayed(const Duration(milliseconds: 250));
            results.add(1);
          }, 0),
          PriorityTask(2, (_) async => results.add(2), 0),
          PriorityTask(3, (_) async => results.add(3), 0),
          PriorityTask(4, (_) async => results.add(4), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.executeAll();

      expect(results, []);
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 3);

      executor.changePriority(4, 10);

      await Future.delayed(const Duration(milliseconds: 210));
      expect(results.sublist(0, 2), [0, 4]);
    });
  });
}
