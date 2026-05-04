import 'package:flutter/material.dart';

class FileUtils {
  /// Determines the appropriate icon based on the file extension from the location path.
  static IconData getFileIcon(String? path) {
    if (path == null || path.isEmpty) return Icons.insert_drive_file_outlined;

    // Extract the extension by finding the last dot and ignoring query parameters
    final String fileName = path.split('/').last;
    if (!fileName.contains('.')) return Icons.insert_drive_file_outlined;

    final String extension = fileName
        .split('.')
        .last
        .split('?')
        .first
        .toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam_outlined;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return Icons.audiotrack_outlined;
      case 'txt':
        return Icons.text_snippet_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
