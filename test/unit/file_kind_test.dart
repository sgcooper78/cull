import 'package:cull/core/file_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileKindOf', () {
    test('images across many formats', () {
      for (final n in [
        'a.jpg',
        'a.JPEG',
        'a.png',
        'a.gif',
        'a.webp',
        'a.bmp',
        'a.tif',
        'a.tiff',
        'a.tga',
        'a.ico',
        'a.psd',
        'a.exr',
        'a.heic',
        'a.heif',
        'a.avif',
        'a.jxl',
        'a.cr2',
        'a.nef',
        'a.arw',
        'a.dng',
        'a.raf',
        'a.orf',
      ]) {
        expect(fileKindOf(n), FileKind.image, reason: n);
      }
    });

    test('video across many formats', () {
      for (final n in [
        'v.mp4',
        'v.mkv',
        'v.mov',
        'v.avi',
        'v.webm',
        'v.wmv',
        'v.flv',
        'v.mpeg',
        'v.mpg',
        'v.m2ts',
        'v.ts',
        'v.3gp',
        'v.ogv',
        'v.rmvb',
        'v.vob',
        'v.mxf',
      ]) {
        expect(fileKindOf(n), FileKind.video, reason: n);
      }
    });

    test('audio across many formats', () {
      for (final n in [
        's.mp3',
        's.flac',
        's.wav',
        's.aac',
        's.m4a',
        's.ogg',
        's.opus',
        's.wma',
        's.aiff',
        's.ape',
        's.wv',
        's.mka',
        's.ac3',
        's.dsf',
      ]) {
        expect(fileKindOf(n), FileKind.audio, reason: n);
      }
    });

    test('pdf', () {
      expect(fileKindOf('doc.pdf'), FileKind.pdf);
      expect(fileKindOf('DOC.PDF'), FileKind.pdf);
    });

    test('comics', () {
      for (final n in ['x.cbz', 'x.cbr', 'x.cb7', 'x.cbt', 'x.cba']) {
        expect(fileKindOf(n), FileKind.comic, reason: n);
      }
    });

    test('non-comic archives', () {
      for (final n in ['a.zip', 'a.tar.gz', 'a.7z', 'a.rar', 'a.xz', 'a.iso']) {
        expect(fileKindOf(n), FileKind.archive, reason: n);
      }
    });

    test('popular text / code / config files', () {
      for (final n in [
        'a.txt',
        'a.md',
        'a.rst',
        'a.json',
        'a.yaml',
        'a.toml',
        'a.xml',
        'a.csv',
        'a.ini',
        'a.dart',
        'a.py',
        'a.rs',
        'a.go',
        'a.tsx',
        'a.sh',
        'a.sql',
        'a.css',
        'a.html',
        'a.svg',
        'a.srt',
        'a.vtt',
      ]) {
        expect(fileKindOf(n), FileKind.text, reason: n);
      }
    });

    test('.ts is treated as MPEG-TS video, not TypeScript', () {
      expect(fileKindOf('stream.ts'), FileKind.video);
    });

    test('well-known extensionless names are text', () {
      for (final n in [
        'README',
        'LICENSE',
        'CHANGELOG',
        'Dockerfile',
        'Makefile',
        '.gitignore',
        '.env',
        '.bashrc',
        'Gemfile',
      ]) {
        expect(fileKindOf(n), FileKind.text, reason: n);
        expect(fileKindOf('/some/dir/$n'), FileKind.text, reason: n);
      }
    });

    test('unknown extension / bare name is other', () {
      expect(fileKindOf('firmware.bin'), FileKind.other);
      expect(fileKindOf('mystery'), FileKind.other);
      expect(fileKindOf('data.dat'), FileKind.other);
    });

    test('isMedia covers image/video/audio only', () {
      expect(FileKind.image.isMedia, isTrue);
      expect(FileKind.video.isMedia, isTrue);
      expect(FileKind.audio.isMedia, isTrue);
      expect(FileKind.pdf.isMedia, isFalse);
      expect(FileKind.comic.isMedia, isFalse);
      expect(FileKind.archive.isMedia, isFalse);
    });
  });

  group('imageSupportOf', () {
    test('native decoders', () {
      for (final n in ['a.jpg', 'a.png', 'a.gif', 'a.webp', 'a.bmp']) {
        expect(imageSupportOf(n), ImageSupport.native, reason: n);
      }
    });

    test('image-package decoders', () {
      for (final n in ['a.tif', 'a.tga', 'a.ico', 'a.psd', 'a.pcx']) {
        expect(imageSupportOf(n), ImageSupport.package, reason: n);
      }
    });

    test('no pure-Dart decoder', () {
      for (final n in ['a.heic', 'a.avif', 'a.jxl', 'a.cr2', 'a.dng']) {
        expect(imageSupportOf(n), ImageSupport.unsupported, reason: n);
      }
    });
  });

  group('comicIsReadable', () {
    test('zip/tar comics are readable', () {
      expect(comicIsReadable('x.cbz'), isTrue);
      expect(comicIsReadable('x.cbt'), isTrue);
    });
    test('rar/7z comics are not', () {
      expect(comicIsReadable('x.cbr'), isFalse);
      expect(comicIsReadable('x.cb7'), isFalse);
      expect(comicIsReadable('x.cba'), isFalse);
    });
  });
}
