import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

void main() {
  final ipaFile = File('build/ios/ipa/Customer_App.ipa');
  if (!ipaFile.existsSync()) {
    stderr.writeln('❌ FATAL: Customer_App.ipa was not found in build/ios/ipa!');
    exit(1);
  }

  final bytes = ipaFile.readAsBytesSync();
  final digest = sha256.convert(bytes);
  stdout.writeln('\n======================================================');
  stdout.writeln('📋 CUSTOMER IPA ARTIFACT VERIFICATION:');
  stdout.writeln('File: Customer_App.ipa');
  stdout.writeln('Size: ${bytes.length} bytes (${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB)');
  stdout.writeln('SHA-256: ${digest.toString().toUpperCase()}');

  final archive = ZipDecoder().decodeBytes(bytes);

  bool foundDiagString = false;
  for (final file in archive) {
    if (file.name.contains('App.framework/App')) {
      final content = file.content as List<int>;
      final str = utf8.decode(content, allowMalformed: true);
      if (str.contains('DIAGNOSTIC TEST: BUILD e7a3bf0')) {
        foundDiagString = true;
      }
    }
  }

  if (foundDiagString) {
    stdout.writeln('🎯 DIAGNOSTIC BUILD FOUND INSIDE FINAL IPA: YES');
    stdout.writeln('======================================================\n');
  } else {
    stderr.writeln('❌ FATAL: DIAGNOSTIC TEST STRING NOT FOUND IN FINAL IPA!');
    stderr.writeln('Build failed because final IPA does not contain latest code.');
    exit(1);
  }
}
