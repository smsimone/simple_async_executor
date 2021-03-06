import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simple_async_executor/simple_async_executor.dart';

void main() {
  runApp(const Example());
}

class Example extends StatefulWidget {
  const Example({Key? key}) : super(key: key);

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final _stream = StreamController<int>.broadcast();

  final _executor = BaseExecutor<void>(
    maxConcurrentTasks: 1,
  );

  @override
  void initState() {
    super.initState();
    <AsyncTask<void>>[
      AsyncTask(0, () async => _stream.add(0)),
      AsyncTask(1, () async => _stream.add(1)),
      AsyncTask(2, () async => _stream.add(1)),
      AsyncTask(3, () async => _stream.add(1)),
    ].forEach(_executor.addTask);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              StreamBuilder<int>(
                  stream: _stream.stream,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data?.toString() ?? '-',
                      style: Theme.of(context).textTheme.headline4,
                    );
                  }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _executor.start(),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
