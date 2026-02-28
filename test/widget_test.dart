/// PlantDoctor Widget Tests
///
/// Basic widget tests for the PlantDoctor app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planty/main.dart';

void main() {
  testWidgets('PlantDoctor app renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlantDoctorApp());

    // Wait for any animations to complete
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the app title is present
    expect(find.text('PlantDoctor'), findsOneWidget);
  });
}
