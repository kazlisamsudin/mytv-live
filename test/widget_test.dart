import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytv_live/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('search filters channels and favourites are saved',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyTvLiveApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'TV3');
    await tester.pumpAndSettle();
    expect(find.text('TV3'), findsWidgets);
    expect(find.text('TV1'), findsNothing);

    await tester.tap(find.byTooltip('Add TV3 to favourites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(find.text('TV3'), findsWidgets);
    expect(find.text('TV1'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('favorite_channel_ids'), contains('tv3'));
  });
}