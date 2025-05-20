import 'dart:io';
import 'package:facetrust/controller/ImageController.dart';
import 'package:facetrust/pages/camera_page.dart';
import 'package:facetrust/pages/image_viewer.dart';
import 'package:facetrust/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:camera/camera.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ImageController controller = Get.put(ImageController());

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'VKYC Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Tap the button below to start your VKYC (Video KYC) process',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final cameras = await availableCameras();
              if (cameras.isNotEmpty) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );

                if (result != null && result is String) {
                  await controller.loadImages();
                }
              } else {
                displaySnackBar(
                    context,
                    "Camera not Active !",
                    Icons.verified_user,
                    const Color(0xFFD32F2F),
                    Color(0xFFFFE5E5));
              }
            },
            icon: const Icon(Icons.verified_user),
            label: const Text(
              "Verify Now",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Saved VKYC Photos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.imageFiles.isEmpty) {
                return const Center(
                  child: Text(
                    "No images found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.imageFiles.length,
                itemBuilder: (context, index) {
                  final file = controller.imageFiles[index];
                  final modified = file.statSync().modified;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(file.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        p.basename(file.path),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Captured: ${formatDate(modified)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ImageViewer(imagePath: file.path),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () async {
                          await controller.deleteImage(file);
                          displaySnackBar(
                              context,
                              "Image Deleted Successfully..!!!",
                              Icons.check_circle,
                              const Color(0xFFEF6C00),
                              Color(0xFFFFF8E1));
                        },
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
