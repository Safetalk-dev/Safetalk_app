// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('SafeTalk app launches and displays welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SafeTalkApp());

    // Verify that our Welcome starting elements render
    expect(find.text('safe talk'), findsOneWidget);
    expect(find.text('I need to share'), findsOneWidget);
    expect(find.text('I am here to listen'), findsOneWidget);
  });

  testWidgets('Selecting role transitions to specialized login page', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeTalkApp());

    // Tap "I need to share"
    await tester.tap(find.text('I need to share'));
    await tester.pump(const Duration(milliseconds: 500)); // Play route animations

    // Verify we have navigated to the Seeker login
    expect(find.text('Welcome, Seeker'), findsOneWidget);
    expect(find.text('CONFIDENTIAL EMAIL ADDRESS'), findsOneWidget);
    
    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump(const Duration(milliseconds: 500)); // Play back animations

    // Verify we are back on the starting welcome page
    expect(find.text('I need to share'), findsOneWidget);
  });
}
