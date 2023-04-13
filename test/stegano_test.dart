import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stegano/stegano.dart';

import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  test('encode&decode', () async {
    final stegano = Stegano();
    var client = http.Client();

    http.Response response = await client.get(Uri.parse('https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/560px-PNG_transparency_demonstration_1.png'));

    final img.Image? originalImage = img.decodeImage(response.bodyBytes.buffer.asUint8List());

    if (originalImage == null) {
      throw Exception('Failed to decode image.');
    }

    ByteBuffer data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).buffer;
    String key = 'my 32 length key................';

    img.Image result = await stegano.encode(originalImage, key, data);
    expect(result, isNotNull);

    ByteBuffer resultData = await stegano.decode(result, key);

    expect(resultData, isNotNull);
    expect(resultData.lengthInBytes, data.lengthInBytes);
    expect(resultData.asUint8List(), data.asUint8List());
  });

  test('throw exception data exceed container size', () {

  });
}
