import 'package:flutter/material.dart';
import 'package:simple_async_executor/simple_async_executor.dart';
import 'package:test/test.dart';

void main() {
  group('PriorityExecutor', () {
    test('All items have the same priority', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void>(
        initialTasks: [
          PriorityTask(0, () async => results.add(0), 0),
          PriorityTask(1, () async => results.add(1), 0),
          PriorityTask(2, () async => results.add(2), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();

      await executor.waitUntilDone;

      expect(results, [2, 1, 0]);
    });

    test('All items have the same priority -- some tasks slower', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void>(
        initialTasks: [
          PriorityTask(0, () async {
            await Future.delayed(const Duration(milliseconds: 200));
            results.add(0);
          }, 0),
          PriorityTask(1, () async {
            await Future.delayed(const Duration(milliseconds: 200));
            results.add(1);
          }, 0),
          PriorityTask(2, () async => results.add(2), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();

      await Future.delayed(const Duration(milliseconds: 20));

      expect(results, [2]);
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 0);
    });

    test('Edit priority of one task at runtime', () async {
      final results = <int>[];

      final executor = PriorityExecutor<void>(
        initialTasks: [
          PriorityTask(
            0,
            () async {
              await Future.delayed(const Duration(milliseconds: 200));
              results.add(0);
            },
            9,
          ),
          PriorityTask(
            1,
            () async {
              await Future.delayed(const Duration(milliseconds: 250));
              results.add(1);
            },
            9,
          ),
          PriorityTask(2, () async => results.add(2), 0),
          PriorityTask(3, () async => results.add(3), 0),
          PriorityTask(4, () async => results.add(4), 0),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();

      expect(results, []);
      debugPrint('---First assert done');
      await Future.delayed(const Duration(milliseconds: 60));
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 3);

      executor.changePriority(4, 10);

      await executor.getResult(4);
      expect(results.first, 0);
      expect(results[1], 4);
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 1);
    });

    test(
      'Change priority of tasks added after initialization while running',
      () async {
        final results = <int>[];

        final tasks = List.generate(
          10,
          (index) => PriorityTask(
            index.hashCode,
            () async {
              if (index.isOdd) {
                await Future.delayed(const Duration(milliseconds: 200));
              }
              results.add(index);
            },
            0,
          ),
        );

        final executor = PriorityExecutor<void>(
          maxConcurrentTasks: 3,
        );

        expect(executor.runningTasks, 0);

        tasks.forEach(executor.addTask);

        executor.start();

        final edits = {
          10: tasks.where((t) => t.id.isEven).map((i) => i.id).toList(),
          0: tasks.where((t) => t.id.isOdd).map((i) => i.id).toList(),
        };

        executor.bulkChangePriority(edits);

        await executor.waitUntilDone;
        expect(
          results.sublist(0, 5).every((element) => element.isEven),
          isTrue,
          reason: 'First half of the list should be even',
        );
        expect(
          results.sublist(5).every((element) => element.isOdd),
          isTrue,
          reason: 'The other half should have only odd elements',
        );
      },
    );

    test(
      'Change execution order before running',
      () async {
        final results = <int>[];

        final tasks = List.generate(
          10,
          (index) => PriorityTask(
            index.hashCode,
            () async => results.add(index),
            0,
          ),
        );

        final executor = PriorityExecutor<void>(
          maxConcurrentTasks: 3,
        );

        expect(executor.runningTasks, 0);

        tasks.forEach(executor.addTask);

        final edits = {
          10: tasks.where((t) => t.id.isEven).map((i) => i.id).toList(),
          0: tasks.where((t) => t.id.isOdd).map((i) => i.id).toList(),
        };

        executor.bulkChangePriority(edits);

        executor.start();

        await executor.waitUntilDone;
        expect(
          results.sublist(0, 5).every((element) => element.isEven),
          isTrue,
          reason: 'First half of the list should be even',
        );
        expect(
          results.sublist(5).every((element) => element.isOdd),
          isTrue,
          reason: 'The other half should have only odd elements',
        );
      },
    );
  });
}
