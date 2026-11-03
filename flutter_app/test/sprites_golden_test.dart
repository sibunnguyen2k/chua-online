import 'package:chua_online/widgets/sprites/sprite.dart';
import 'package:chua_online/widgets/sprites/sprites.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sprite sheet', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final items = <SpriteDraw>[
      (c) => drawBuddha(c, t: 0.25),
      (c) => drawMonk(c, pose: MonkPose.idle),
      (c) => drawMonk(c, pose: MonkPose.praying),
      (c) => drawMonk(c, pose: MonkPose.tapping, strike: 0),
      (c) => drawWoodenFish(c, strike: 0),
      (c) => drawWoodenFish(c, strike: 1),
      (c) => drawIncenseBurner(c, t: 0.3, sticks: 3),
      (c) => drawCandle(c),
      (c) => drawOilLamp(c),
      (c) => drawLotus(c),
      (c) => drawFlowerVase(c),
      (c) => drawFruitPlate(c),
      (c) => drawRiceBowl(c),
      (c) => drawBell(c),
      (c) => drawLantern(c),
      (c) => drawPrayerBeads(c),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        body: Wrap(children: [
          for (final d in items)
            Padding(
                padding: const EdgeInsets.all(10),
                child: Sprite(draw: d, size: 260))
        ]),
      ),
    ));
    await expectLater(
        find.byType(Scaffold), matchesGoldenFile('goldens/sprites.png'));
  });
}
