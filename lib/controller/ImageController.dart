import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class ImageController extends GetxController {
  var imageFiles = <FileSystemEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  Future<void> loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final allFiles = dir.listSync();
    final images =
        allFiles.where((file) => file.path.endsWith('.jpg')).toList();
    images
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    imageFiles.assignAll(images);
  }

  Future<void> deleteImage(FileSystemEntity file) async {
    try {
      final f = File(file.path);
      if (await f.exists()) {
        await f.delete();
        imageFiles.remove(file);
      }
    } catch (e) {
      print(e);
    }
  }
}
