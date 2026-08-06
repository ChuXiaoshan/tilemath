import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/ui/pattern_preview.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('按 size 渲染正方形 CustomPaint（量尺寸）', (tester) async {
    await tester.pumpWidget(host(PatternPreview(
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      size: 84,
    )));
    final paint = find.byType(CustomPaint).last;
    expect(tester.getSize(paint), const Size(84, 84));
  });

  testWidgets('参数变化触发重绘（shouldRepaint）', (tester) async {
    final painterA = PatternPreviewPainter(
      tileWmm: 300, tileHmm: 300, groutMm: 2,
      pattern: LayoutPattern.straight,
      tileColor: const Color(0xFFD7D3D3),
      groutColor: const Color(0xFFEAE9E9),
    );
    final painterB = PatternPreviewPainter(
      tileWmm: 300, tileHmm: 300, groutMm: 4, // 缝宽变了
      pattern: LayoutPattern.straight,
      tileColor: const Color(0xFFD7D3D3),
      groutColor: const Color(0xFFEAE9E9),
    );
    expect(painterB.shouldRepaint(painterA), isTrue);
    expect(painterA.shouldRepaint(painterA), isFalse);
  });
}
