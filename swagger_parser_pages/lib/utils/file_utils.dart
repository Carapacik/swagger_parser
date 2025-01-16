import 'dart:convert';
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
    final contentBytes = utf8.encode(file.content);
    archive.addFile(ArchiveFile(file.name, contentBytes.length, contentBytes));
  }
  final outputStream = OutputMemoryStream();
  final bytes = encoder.encode(
    archive,
    level: DeflateLevel.bestCompression,
    output: outputStream,
  );

  final blobWeb = web.Blob(<JSUint8Array>[Uint8List.fromList(bytes).toJS].toJS);
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
