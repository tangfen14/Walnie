import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class EncodedEventImage {
  const EncodedEventImage({required this.mimeType, required this.base64});

  final String mimeType;
  final String base64;
}

Future<EncodedEventImage> encodeEventImage(
  XFile file, {
  int maxDimension = 1280,
  int quality = 70,
}) async {
  final original = await file.readAsBytes();
  final compressed = await FlutterImageCompress.compressWithList(
    original,
    quality: quality,
    minHeight: maxDimension,
    minWidth: maxDimension,
    format: CompressFormat.jpeg,
    keepExif: false,
  );

  final bytes = compressed.isEmpty ? original : Uint8List.fromList(compressed);
  return EncodedEventImage(mimeType: 'image/jpeg', base64: base64Encode(bytes));
}
