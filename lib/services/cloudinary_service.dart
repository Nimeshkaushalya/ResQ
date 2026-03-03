import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary =
      CloudinaryPublic('dk8s78zih', '669345519793145', cache: false);

  Future<String?> uploadImage(File image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary error: ${e.message}');
      print('Cloudinary request: ${e.request}');
      return null;
    } catch (e) {
      print('Unknown error during image upload: $e');
      return null;
    }
  }

  Future<String?> uploadVideo(File video) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(video.path,
            resourceType: CloudinaryResourceType.Video),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary error: ${e.message}');
      print('Cloudinary request: ${e.request}');
      return null;
    } catch (e) {
      print('Unknown error during video upload: $e');
      return null;
    }
  }
}
