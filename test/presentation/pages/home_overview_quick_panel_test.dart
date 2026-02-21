import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/widgets/overview_quick_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<OverviewQuickItem> buildItems() {
    return const [
      OverviewQuickItem(
        type: EventType.feed,
        title: '喂奶',
        value: '9',
        icon: Icons.local_drink,
      ),
      OverviewQuickItem(
        type: EventType.diaper,
        title: '换尿布',
        value: '5',
        icon: Icons.checkroom,
      ),
      OverviewQuickItem(
        type: EventType.poop,
        title: '便便',
        value: '5',
        icon: Icons.baby_changing_station,
      ),
      OverviewQuickItem(
        type: EventType.pee,
        title: '尿尿',
        value: '5',
        icon: Icons.water_drop,
      ),
      OverviewQuickItem(
        type: EventType.pump,
        title: '吸奶',
        value: '0',
        icon: Icons.science,
      ),
    ];
  }

  Widget buildTestWidget({
    EventType? selectedType,
    void Function(EventType type)? onSelectFilter,
    void Function(EventType type)? onAddEvent,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OverviewQuickPanel(
          items: buildItems(),
          selectedType: selectedType,
          onSelectFilter: onSelectFilter ?? (_) {},
          onAddEvent: onAddEvent ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders five cards with values', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.byKey(const ValueKey('overview-card-feed')), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-card-diaper')), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-card-poop')), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-card-pee')), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-card-pump')), findsOneWidget);

    expect(find.text('喂奶'), findsOneWidget);
    expect(find.text('换尿布'), findsOneWidget);
    expect(find.text('便便'), findsOneWidget);
    expect(find.text('尿尿'), findsOneWidget);
    expect(find.text('吸奶'), findsOneWidget);
  });

  testWidgets('tap card body triggers filter callback', (tester) async {
    EventType? selectedType;
    await tester.pumpWidget(
      buildTestWidget(
        onSelectFilter: (type) {
          selectedType = type;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('overview-filter-feed')));
    await tester.pump();

    expect(selectedType, EventType.feed);
  });

  testWidgets('tap record button triggers add callback', (tester) async {
    EventType? addType;
    await tester.pumpWidget(
      buildTestWidget(
        onAddEvent: (type) {
          addType = type;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('overview-record-feed')));
    await tester.pump();

    expect(addType, EventType.feed);
  });

  testWidgets('tap record button does not trigger filter', (tester) async {
    EventType? selectedType;
    EventType? addType;
    await tester.pumpWidget(
      buildTestWidget(
        onSelectFilter: (type) {
          selectedType = type;
        },
        onAddEvent: (type) {
          addType = type;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('overview-record-diaper')));
    await tester.pump();

    expect(addType, EventType.diaper);
    expect(selectedType, isNull);
  });

  testWidgets('selected type has selected semantics', (tester) async {
    await tester.pumpWidget(buildTestWidget(selectedType: EventType.pump));

    final selectedSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('overview-card-pump')),
    );
    final unselectedSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('overview-card-feed')),
    );

    expect(selectedSemantics.properties.selected, isTrue);
    expect(unselectedSemantics.properties.selected, isFalse);
  });

  testWidgets('no overflow on small screen width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(buildTestWidget());

    expect(tester.takeException(), isNull);
  });
}
