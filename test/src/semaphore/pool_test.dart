import 'package:simple_async_executor/src/semaphore/pool.dart';
import 'package:test/test.dart';

void main() {
  group('Priority pool', () {
    test('Items with the same priority', () async {
      final pool = PriorityPool<String>(
        (a, b) => a.priority.compareTo(b.priority),
        defaultPriority: 0,
      );

      for (var i in ['a', 'b', 'c']) {
        pool.add(() async => i);
      }

      expect(pool.length, 3);
      expect(await pool.removeFirst().item(), 'c');
      expect(await pool.removeFirst().item(), 'b');
      expect(await pool.removeFirst().item(), 'a');
    });

    test('Change item priority', () async {
      final pool = PriorityPool<String>(
        (a, b) => b.priority.compareTo(a.priority),
        defaultPriority: 0,
      );

      for (var i in ['a', 'b', 'c']) {
        pool.add(() async => i, i.hashCode);
      }

      expect(pool.length, 3);
      pool.changePriority('a'.hashCode, 5);
      expect(await pool.removeFirst().item(), 'a');
    });
  });
}
