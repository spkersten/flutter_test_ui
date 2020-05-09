# flutter_test_ui

Wrapper of `testWidgets`, `setUp`, and `tearDown` that provide the `WidgetTesterCallback` argument
to the set-up and tear-down functions: `testUI`, `setUpUI`, and `tearDownUI`.

This allows a single set-up to be shared by several tests and the set-up to be continued in subgroups.
In particular, it allows test to be written in rspec style for better readability.

```dart
group("testUI and setUpUI example test", () {
  setUpUI((tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => Container(
                color: Colors.green,
                child: const Text("page 2"),
              ),
            ),
          ),
          child: Container(
            color: Colors.red,
            child: const Text("page 1"),
          ),
        ),
      ),
    ));
  });

  testUI("first page is shown", (tester) async {
    expect(find.text("page 1"), findsOneWidget);
  });

  group("tapping the text", () {
    setUpUI((tester) async {
      await tester.tap(find.text("page 1"));
      await tester.pumpAndSettle();
    });

    testUI("second page is shown", (tester) async {
      expect(find.text("page 2"), findsOneWidget);
    });

    group("pop the second page", () {
      setUpUI((tester) async {
        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pop();
        await tester.pumpAndSettle();
      });

      testUI("second page isn't visible anymore", (tester) async {
        expect(find.text("page 2"), findsNothing);
      });

      testUI("first page is visible again", (tester) async {
        expect(find.text("page 1"), findsOneWidget);
      });
    });
  });
});
```