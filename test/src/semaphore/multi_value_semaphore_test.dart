import 'dart:async';

import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:test/test.dart';

void main() {
  group('Multi-value semaphore', () {
    test('All tasks can be executed instantly', () async {
      final semaphore = Semaphore(5);

      final results = <int>[];
      semaphore.addToQueue(() async => results.add(1), 1);
      semaphore.addToQueue(() async => results.add(2), 2);
      semaphore.addToQueue(() async => results.add(3), 3);

      expect(results, isEmpty);

      semaphore.start();
      await Future.delayed(const Duration(microseconds: 50));

      expect(results, [1, 2, 3]);
    });

    test('One task will not be ended', () async {
      final semaphore = Semaphore(2);

      final results = <int>[];
      semaphore.addToQueue(() async => results.add(1), 1);
      semaphore.addToQueue(
        () async {
          await Future.delayed(const Duration(seconds: 2));
          results.add(2);
        },
        2,
      );
      semaphore.addToQueue(() async => results.add(3), 3);

      expect(results, isEmpty);

      semaphore.start();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(results, [1, 3]);
      expect(semaphore.runningTasks, 1);
      expect(semaphore.waitingTasks, 0);
    });

    test('One task will not be executed', () async {
      final semaphore = Semaphore(1);

      final results = <int>[];
      semaphore.addToQueue(() async => results.add(1), 1);
      semaphore.addToQueue(() async {
        await Future.delayed(const Duration(seconds: 2));
        results.add(2);
      }, 2);
      semaphore.addToQueue(() async => results.add(3), 3);

      expect(results, isEmpty);

      semaphore.start();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(semaphore.runningTasks, 1);
      expect(semaphore.waitingTasks, 1);
      expect(results, [1]);
    });

    test(
      'Has some thread running - disposes every task - all incompleted',
      () async {
        final semaphore = Semaphore(1);

        semaphore.addToQueue(
          () async => await Future.delayed(const Duration(seconds: 2)),
          0,
        );
        semaphore.addToQueue(
          () async => await Future.delayed(const Duration(seconds: 2)),
          1,
        );

        semaphore.start();
        await Future.delayed(const Duration(milliseconds: 50));
        expect(semaphore.runningTasks, 1);
        expect(semaphore.waitingTasks, 1);
        semaphore.dispose();
        expect(semaphore.runningTasks, 0);
        expect(semaphore.waitingTasks, 0);
        expect(semaphore.isDisposed, isTrue);
      },
    );

    test(
      'Has some thread running - disposes every task - one completed',
      () async {
        final semaphore = Semaphore(1);

        final completer = Completer();

        semaphore.addToQueue(
          () async {
            await Future.delayed(const Duration(seconds: 2));
            completer.complete();
          },
          0,
        );
        semaphore.addToQueue(
          () async => await Future.delayed(const Duration(seconds: 2)),
          1,
        );

        semaphore.start();
        await completer.future;
        await Future.delayed(const Duration(milliseconds: 50));
        expect(semaphore.runningTasks, 1);
        expect(semaphore.waitingTasks, 0);
        semaphore.dispose();
        expect(semaphore.runningTasks, 0);
        expect(semaphore.waitingTasks, 0);
        expect(semaphore.completedTasks, 1);
        expect(semaphore.isDisposed, isTrue);
      },
    );
  });
}
