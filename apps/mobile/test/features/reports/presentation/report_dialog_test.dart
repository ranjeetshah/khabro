import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/report_reason.dart';
import 'package:mobile/features/reports/presentation/report_dialog.dart';

class _Host extends StatelessWidget {
  const _Host({required this.onSubmit});

  final Future<void> Function(ReportReason reason, String? description)
  onSubmit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                await showReportDialog(
                  context,
                  title: 'Report post',
                  onSubmit: onSubmit,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('submit stays disabled until a reason is chosen', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(_Host(onSubmit: (_, _) async => calls++));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Submit report');
    expect(submit, findsOneWidget);
    await tester.tap(submit);
    await tester.pump();
    expect(calls, 0);

    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('submits the wire reason and trimmed optional description', (
    tester,
  ) async {
    ReportReason? sentReason;
    String? sentDescription;
    await tester.pumpWidget(
      _Host(
        onSubmit: (reason, description) async {
          sentReason = reason;
          sentDescription = description;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('False information'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Misleading claim  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();

    expect(sentReason, ReportReason.falseInformation);
    expect(sentDescription, 'Misleading claim');
  });

  testWidgets('blank description is sent as null', (tester) async {
    String? sentDescription = 'sentinel';
    await tester.pumpWidget(
      _Host(
        onSubmit: (reason, description) async => sentDescription = description,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();
    expect(sentDescription, isNull);
  });

  testWidgets('errors show a message and retry recovers', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _Host(
        onSubmit: (_, _) async {
          calls++;
          if (calls == 1) throw Exception('boom');
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harassment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('duplicate taps are ignored while a request is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _Host(onSubmit: (_, _) {
        calls++;
        return completer.future;
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dangerous content'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(calls, 1);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('success shows a neutral confirmation without internal ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(onSubmit: (_, _) async {}),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('report-1'), findsNothing);
    expect(find.text('Report status'), findsNothing);
    expect(find.text('Moderation'), findsNothing);
    expect(find.text('JWT'), findsNothing);
    expect(find.text('locality'), findsNothing);
    expect(find.text('coordinates'), findsNothing);
  });
}
