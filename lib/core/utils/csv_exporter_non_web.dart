import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveCsvFile(String csvContent, String filename) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(csvContent);
  await Share.shareXFiles([XFile(file.path)], text: 'Exported Group Expenses CSV');
}
