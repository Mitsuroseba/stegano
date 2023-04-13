library stegano;


import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'dart:ui';
import 'dart:ui' as ui;


// TODO use this instead.
import 'package:image/image.dart' as img;
import 'package:stegano/image_wrapper.dart';

class Stegano {

  ImageWrapper imageWrapper = ImageWrapper();

  Future<img.Image> encode(img.Image imageImage, String key, ByteBuffer data) async {

    Image image = await imageWrapper.getUiImageFromImageImage(imageImage);
    // Load image byte data
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to load image bytes.');
    }

    Uint8List imageBytes = byteData.buffer.asUint8List();

    // Encrypt data with AES
    final plainText = base64.encode(data.asUint8List()); // encode data as base64
    final encryptionKey = Key.fromUtf8(key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(encryptionKey));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Embed the encrypted data into the image
    String encryptedData = encrypted.base64;
    int dataLength = encryptedData.length;
    int imageCapacity = imageBytes.length ~/ 8;

    if (dataLength > imageCapacity) {
      throw Exception('Data is too large for the image.');
    }

    for (int i = 0; i < dataLength; i++) {
      // Embed each character of the encrypted data into the corresponding pixel byte
      int charCode = encryptedData.codeUnitAt(i);
      int pixelByteIndex = i * 8;
      for (int j = 0; j < 8; j++) {
        int bitIndex = 7 - j;
        int bit = (charCode >> bitIndex) & 1;
        int pixelByte = imageBytes[pixelByteIndex];
        pixelByte = (pixelByte & 0xFE) | bit; // clear LSB and embed the bit
        imageBytes[pixelByteIndex] = pixelByte;
        pixelByteIndex++;
      }
    }

    // Create the embedded image
    return imageWrapper.getImageImageFromByteBuffer(imageBytes.buffer);
  }

  Future<ByteBuffer> decode(img.Image imageImage, String key) async {
    Image image = await imageWrapper.getUiImageFromImageImage(imageImage);

    // Load image byte data
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to load image bytes.');
    }

    Uint8List imageBytes = byteData.buffer.asUint8List();

    // Extract the embedded encrypted data from the image
    String encryptedData = '';
    for (int i = 0; i < imageBytes.length; i += 8) {
      // Extract each LSB from the corresponding pixel byte and assemble the encrypted data characters
      int charCode = 0;
      for (int j = 0; j < 8; j++) {
        int pixelByte = imageBytes[i + j];
        int bit = pixelByte & 1;
        charCode = (charCode << 1) | bit; // shift left and add the bit
      }
      if (charCode == 0) {
        // The encrypted data ends with a null character, so we can stop extracting
        break;
      }
      encryptedData += String.fromCharCode(charCode);
    }

    // Decrypt the embedded encrypted data with AES
    final decryptionKey = Key.fromUtf8(key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(decryptionKey));
    final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
    final decryptedBytes = base64.decode(decrypted); // decode the decrypted data from base64

    return decryptedBytes.buffer;
  }
}