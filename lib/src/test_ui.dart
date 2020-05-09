import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// Registers a function to be run before tests.
///
/// Functions registered by [setUpUI] will be run after all other functions registered by [setUp] in parent or
/// child groups. The functions will only be run when [testUI] is used to create the test case.
void setUpUI(WidgetTesterCallback cb) {
  final setUpFunction = _UniqueWrapper(cb, StackTrace.current);
  setUp(() {
    setUpFunction.ran = false;
    _setUpUIs.add(setUpFunction);
  });
  tearDown(() {
    assert(_setUpUIs.contains(setUpFunction));
    assert(
      setUpFunction.ran,
      "A setUpUI function wasn't run. Likely, this means that testWidgets was used to create the test instead of testUI.\n"
      "${setUpFunction.stackTrace}",
    );
    _setUpUIs.remove(setUpFunction);
  });
  tearDownAll(() {
    assert(_setUpUIs.isEmpty);
  });
}

/// Registers a function to be run after tests.
///
/// Functions registered by [tearDownUI] will be run before all other functions registered by [tearDown] in parent or
/// child groups. The functions will only be run when [testUI] is used to create the test case.
void tearDownUI(WidgetTesterCallback cb) {
  final tearDownFunction = _UniqueWrapper(cb, StackTrace.current);
  setUp(() {
    tearDownFunction.ran = false;
    _tearDownUIs.add(tearDownFunction);
  });
  tearDown(() {
    assert(_tearDownUIs.contains(tearDownFunction));
    assert(
      tearDownFunction.ran,
      "A tearDownUI function wasn't run. Likely, this means that testWidgets was used to create the test instead of testUI.\n"
      "${tearDownFunction.stackTrace}",
    );
    _tearDownUIs.remove(tearDownFunction);
  });
  tearDownAll(() {
    assert(_tearDownUIs.isEmpty);
  });
}

/// Runs the [callback] inside the Flutter test environment.
///
/// Use this function to create test cases instead of [testWidgets] to be able to use [setUpUI] and [tearDownUI].
///
/// See [testWidgets] for details
@isTest
void testUI(
  String description,
  WidgetTesterCallback callback, {
  bool skip = false,
  Timeout timeout,
  Duration initialTimeout,
  bool semanticsEnabled = true,
  TestVariant<Object> variant = const DefaultTestVariant(),
}) {
  testWidgets(
    description,
    (tester) async {
      for (final s in _setUpUIs) await s(tester);
      await callback(tester);
      for (final t in _tearDownUIs.reversed) await t(tester);
    },
    skip: skip,
    timeout: timeout,
    initialTimeout: initialTimeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
  );
}

List _setUpUIs = <_UniqueWrapper>[];
List _tearDownUIs = <_UniqueWrapper>[];

// so every call to setUpUI/tearDownUI can be saved uniquely, even if a setup function were to be registered twice
class _UniqueWrapper {
  _UniqueWrapper(this.callback, this.stackTrace);

  final Future<void> Function(WidgetTester widgetTester) callback;
  final StackTrace stackTrace;
  bool ran = false;

  Future<void> call(WidgetTester tester) {
    ran = true;
    return callback(tester);
  }
}
