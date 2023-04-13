import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as image;

class ImageWrapper {
  Future<Image> getUiImageFromImageImage(image.Image imageImage) async {
    Codec codec = await instantiateImageCodec(image.encodePng(imageImage));
    FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<Image> getUiImageFromByteBuffer(ByteBuffer byteBuffer) async {
    ByteData embeddedByteData = ByteData.view(byteBuffer);

    Codec codec = await instantiateImageCodec(embeddedByteData.buffer.asUint8List());
    FrameInfo frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }

  Future<image.Image> getImageImageFromByteBuffer(ByteBuffer byteBuffer) async {
    image.Image? imageImage = image.decodeImage(byteBuffer.asUint8List());

    if (imageImage == null) {
      // TODO don't touch first 8 bytes.
      throw Exception('Failed to decode image.');
    }

    return imageImage;
  }
}