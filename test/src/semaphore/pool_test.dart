import 'package:simple_async_executor/src/semaphore/pool.dart';
import 'package:test/test.dart';

void main() {
  group('Priority pool', () {
    test('Items with the same priority', () {
      final pool = PriorityPool<String>(
        (a, b) => a.priority.compareTo(b.priority),
        defaultPriority: 0,
      );

      ['a', 'b', 'c'].forEach(pool.add);

      expect(pool.length, 3);
      expect(pool.removeFirst().item, 'c');
      expect(pool.removeFirst().item, 'b');
      expect(pool.removeFirst().item, 'a');
    });

    test('Change item priority', () {
      final pool = PriorityPool<String>(
        (a, b) => b.priority.compareTo(a.priority),
        defaultPriority: 0,
      );

      ['a', 'b', 'c'].forEach(pool.add);

      expect(pool.length, 3);
      pool.changePriority('a'.hashCode, 5);
      expect(pool.removeFirst().item, 'a');
    });
  });
}
