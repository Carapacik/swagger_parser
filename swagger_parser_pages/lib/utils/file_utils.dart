import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:web/web.dart' as web;

void generateArchive(List<GeneratedFile> files) {
  final encoder = ZipEncoder();
  final archive = Archive();
  for (final file in files) {
    archive.addFile(ArchiveFile(file.name, file.content.length, file.content));
  }
  final outputStream = OutputStream();
  final bytes = encoder.encode(
    archive,
    level: Deflate.BEST_COMPRESSION,
    output: outputStream,
  );
  if (bytes == null || bytes is! Uint8List) {
    throw Exception('Error with encode');
  }

  final blobWeb = web.Blob(<JSUint8Array>[bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blobWeb);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = 'generated.zip';
  web.document.body!.children.add(anchor);

  // download
  anchor.click();

  // cleanup
  web.document.body!.children.delete(anchor);
  web.URL.revokeObjectURL(url);
}
