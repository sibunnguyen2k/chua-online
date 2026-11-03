import 'sprite.dart';
import 'sprites.dart';

/// Sprite tương ứng với từng vật phẩm dâng lễ (id khớp backend).
SpriteDraw offeringDraw(String id) => switch (id) {
      'incense' => (c) => drawIncenseBurner(c, sticks: 3),
      'flower' => (c) => drawFlowerVase(c),
      'lamp' => (c) => drawOilLamp(c),
      'fruit' => (c) => drawFruitPlate(c),
      'meal' => (c) => drawRiceBowl(c),
      _ => (c) => drawLotus(c),
    };
