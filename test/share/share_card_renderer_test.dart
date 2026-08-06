import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/share/share_card_renderer.dart';

ShareCardData sample({List<(String, String)>? rows}) => ShareCardData(
      appName: 'TileMath',
      date: 'Aug 6, 2026',
      tilesLabel: 'TILES NEEDED',
      tilesValue: '141',
      wasteLine: '128 tiles + 10% waste',
      rows: rows ??
          const [
            ('Total area', '129.33 ft²'),
            ('Boxes to buy', '17'),
            ('Estimated cost', r'$425.00'),
            ('Grout', '≈ 4.3 lb (2.0 kg)'),
            ('Thinset', '≈ 3 bags · 50 lb'),
          ],
      specLine: '12×12″ tile · 1/16″ grout · Straight · 10% waste',
      footer: 'TileMath — tile calculator with a fraction-inch keyboard',
      tileWmm: 304.8,
      tileHmm: 304.8,
      groutMm: 1.5875,
      pattern: LayoutPattern.straight,
    );

void main() {
  test('输出 1080×1350 PNG', () async {
    final bytes = await renderShareCardPng(sample());
    expect(bytes, isNotEmpty);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1080);
    expect(frame.image.height, 1350);
  });

  test('行数不同也能渲染（未填箱规的短列表）', () async {
    final bytes = await renderShareCardPng(sample(rows: const [
      ('Total area', '129.33 ft²'),
      ('Grout', '≈ 4.3 lb (2.0 kg)'),
      ('Thinset', '≈ 3 bags · 50 lb'),
    ]));
    expect(bytes, isNotEmpty);
  });
}
