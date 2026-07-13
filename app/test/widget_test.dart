import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/shared/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays correctly', (WidgetTester tester) async {
    // Set larger physical size so elements don't get clipped or pushed offscreen
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build LoginScreen directly
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));
    await tester.pump(); // Use pump() instead of pumpAndSettle() due to looping logo animation

    // Verify that our Login starting elements render
    expect(find.text('safe talk'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('CONFIDENTIAL EMAIL ADDRESS'), findsOneWidget);
  });

  testWidgets('Toggling between Sign In and Sign Up modes on LoginScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));
    await tester.pump();

    // Verify we start in "Welcome Back" (Sign In) mode
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Tap "New to SafeTalk? Sign Up"
    await tester.tap(find.text('New to SafeTalk? Sign Up'));
    await tester.pump(const Duration(milliseconds: 100)); // pump once to start state change

    // Verify we transition to "Create an Account" (Sign Up) mode
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Tap "Already registered? Sign In instead"
    await tester.tap(find.text('Already registered? Sign In instead'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify we transition back to "Welcome Back" mode
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
