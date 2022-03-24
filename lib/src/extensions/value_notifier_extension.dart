import 'dart:async';

import 'package:flutter/material.dart';

extension ValueNotifierExtension on ValueNotifier<int> {
  void increment() => value += 1;

  void decrement() => value -= 1;

  /// Returns a [Future] that completes when the current instance
  /// reaches the [value] specified.
  Future<void> waitForValue(int value) {
    final completer = Completer<void>();
    addListener(() {
      if (value == this.value) completer.complete();
    });
    return completer.future;
  }
}
