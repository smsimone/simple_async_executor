import 'package:simple_async_executor/src/semaphore/multi_value_semaphore.dart';
import 'package:test/test.dart';

void main() {
  group('Multi-value semaphore', () {
    test('All tasks can be executed instantly', () {
      final semaphore = Semaphore(5);

      final results = <int>[];
      semaphore.addToQueue(() => results.add(1));
      semaphore.addToQueue(() => results.add(2));
      semaphore.addToQueue(() => results.add(3));

      expect(results, [1, 2, 3]);
    });

    test('One task will not be ended', () {
      final semaphore = Semaphore(2);

      final results = <int>[];
      semaphore.addToQueue(() => results.add(1));
      semaphore.addToQueue(() async {
        await Future.delayed(const Duration(seconds: 2));
        results.add(2);
      });
      semaphore.addToQueue(() => results.add(3));

      expect(results, [1, 3]);
      expect(semaphore.runningTasks, 1);
      expect(semaphore.waitingTasks, 0);
    });

    test('One task will not be executed', () {
      final semaphore = Semaphore(1);

      final results = <int>[];
      semaphore.addToQueue(() => results.add(1));
      semaphore.addToQueue(() async {
        await Future.delayed(const Duration(seconds: 2));
        results.add(2);
      });
      semaphore.addToQueue(() => results.add(3));

      expect(results, [1]);
      expect(semaphore.runningTasks, 1);
      expect(semaphore.waitingTasks, 1);
    });
  });
}
