import 'package:simple_async_executor/src/executors/base_executor.dart';
import 'package:simple_async_executor/src/tasks/async_task.dart';
import 'package:test/test.dart';

void main() {
  group('Tests on base ececutor', () {
    test('Executor is not running', () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async => results.add(1)),
          AsyncTask(2, () async => results.add(2)),
          AsyncTask(3, () async => results.add(3)),
        ],
        maxConcurrentTasks: 3,
      );

      expect(executor.isRunning, isFalse);
      expect(executor.isDone, isFalse);
    });

    test("Executor launched but still hasn't finished", () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async => results.add(1)),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(2);
          }),
          AsyncTask(3, () async => results.add(3)),
        ],
        maxConcurrentTasks: 3,
      );

      executor.start();

      expect(executor.isRunning, isTrue);
      expect(executor.isDone, isFalse);
    });

    test('Executor launched -- wait until done', () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async => results.add(1)),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(2);
          }),
          AsyncTask(3, () async => results.add(3)),
        ],
        maxConcurrentTasks: 3,
      );

      executor.start();

      expect(executor.isRunning, isTrue);
      expect(executor.isDone, isFalse);

      await executor.waitUntilDone;
      expect(executor.isRunning, isFalse);
      expect(executor.isDone, isTrue);
    });

    test('All tasks are run together', () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async => results.add(1)),
          AsyncTask(2, () async => results.add(2)),
          AsyncTask(3, () async => results.add(3)),
        ],
        maxConcurrentTasks: 3,
      );

      executor.start();

      await Future.delayed(const Duration(milliseconds: 10));
      expect(executor.runningTasks, 0);
      expect(executor.waitingTasks, 0);
      expect(results, [1, 2, 3]);
    });

    test('One task completes after the others', () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async => results.add(1)),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(milliseconds: 100));
            results.add(2);
          }),
          AsyncTask(3, () async => results.add(3)),
        ],
        maxConcurrentTasks: 3,
      );

      executor.start();

      await Future.delayed(const Duration(milliseconds: 110));
      expect(executor.runningTasks, 0);
      expect(executor.waitingTasks, 0);
      expect(results, [1, 3, 2]);
    });

    test('One task is never excecuted', () async {
      final results = <int>[];

      final executor = BaseExecutor<void>(
        initialTasks: [
          AsyncTask(1, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(1);
          }),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(2);
          }),
          AsyncTask(3, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(3);
          }),
          AsyncTask(4, () async => results.add(4)),
        ],
        maxConcurrentTasks: 3,
      );

      executor.start();

      await Future.delayed(const Duration(milliseconds: 110));
      expect(executor.runningTasks, 3);
      expect(executor.waitingTasks, 1);
      expect(results, []);
    });

    test('Wait for a result', () async {
      final results = <int>[];

      final executor = BaseExecutor<int>(
        initialTasks: [
          AsyncTask(1, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(1);
            return 1;
          }),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(milliseconds: 60));
            results.add(2);
            return 2;
          }),
          AsyncTask(3, () async {
            results.add(3);
            return 3;
          }),
          AsyncTask(4, () async {
            results.add(4);
            return 4;
          }),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();

      final result = await executor.getResult(3);

      expect(result, 3);
      expect(executor.runningTasks, 2);
      expect(executor.waitingTasks, 0);
      expect(results, [2, 3, 4]);
    });

    test('Wait for the last result', () async {
      final results = <int>[];

      final executor = BaseExecutor<int>(
        initialTasks: [
          AsyncTask(1, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(1);
            return 1;
          }),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(milliseconds: 60));
            results.add(2);
            return 2;
          }),
          AsyncTask(3, () async {
            results.add(3);
            return 3;
          }),
          AsyncTask(4, () async {
            results.add(4);
            return 4;
          }),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();

      final result = await executor.getResult(1);

      expect(result, 1);
      expect(executor.runningTasks, 0);
      expect(executor.waitingTasks, 0);
      expect(results, [2, 3, 4, 1]);
    });

    test('Adds a task at runtime -- no running tasks', () async {
      final results = <int>[];

      final executor = BaseExecutor<int>(
        initialTasks: [
          AsyncTask(1, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(1);
            return 1;
          }),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(milliseconds: 60));
            results.add(2);
            return 2;
          }),
          AsyncTask(3, () async {
            results.add(3);
            return 3;
          }),
          AsyncTask(4, () async {
            results.add(4);
            return 4;
          }),
        ],
        maxConcurrentTasks: 2,
      );

      executor.addTask(AsyncTask(5, () async {
        results.add(5);
        return 5;
      }));

      expect(executor.runningTasks, 0);
      expect(executor.waitingTasks, 5);
      executor.start();
      await executor.getResult(1);
      expect(results, [2, 3, 4, 5, 1]);
      await executor.getResult(5);
      expect(results, [2, 3, 4, 5, 1]);
    });

    test('Adds a task at runtime -- running tasks', () async {
      final results = <int>[];

      final executor = BaseExecutor<int>(
        initialTasks: [
          AsyncTask(1, () async {
            await Future.delayed(const Duration(seconds: 2));
            results.add(1);
            return 1;
          }),
          AsyncTask(2, () async {
            await Future.delayed(const Duration(milliseconds: 60));
            results.add(2);
            return 2;
          }),
          AsyncTask(3, () async {
            results.add(3);
            return 3;
          }),
          AsyncTask(4, () async {
            results.add(4);
            return 4;
          }),
        ],
        maxConcurrentTasks: 2,
      );

      executor.start();
      await Future.delayed(const Duration(milliseconds: 100));
      executor.addTask(
        AsyncTask(
          5,
          () async {
            results.add(5);
            return 5;
          },
        ),
      );

      final result = await executor.getResult(1);

      expect(result, 1);
      expect(executor.runningTasks, 0);
      expect(executor.waitingTasks, 0);
      expect(results, [2, 3, 4, 5, 1]);
    });
  });
}
