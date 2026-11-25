import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/core/motion/app_motion.dart';

void main() {
  testWidgets('Selection keeps its painted position across interrupted moves', (
    tester,
  ) async {
    const marker = ValueKey('painted');
    Widget shell(int index, {bool reduced = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MotionLayout(
            revision: index,
            child: Row(
              children: List.generate(
                3,
                (i) => SizedBox(
                  width: 80,
                  height: 32,
                  child: i == index
                      ? const MotionAnchor(
                          id: 'pill',
                          child: ColoredBox(key: marker, color: Colors.green),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    double x() => tester.getTopLeft(find.byKey(marker)).dx;
    await tester.pumpWidget(shell(0));
    await tester.pumpWidget(shell(2));
    expect(x(), closeTo(0, .01));
    await tester.pump(const Duration(milliseconds: 64));
    final mid = x();
    expect(mid, inExclusiveRange(0, 160));
    await tester.pumpWidget(shell(1));
    expect(x(), closeTo(mid, .01));
    await tester.pumpAndSettle();
    expect(x(), 80);
    await tester.pumpWidget(shell(0, reduced: true));
    expect(x(), 0);
  });
}
