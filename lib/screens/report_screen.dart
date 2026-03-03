import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:resq_flutter/services/cloudinary_service.dart';
import 'package:resq_flutter/services/emergency_service.dart';
import 'package:video_player/video_player.dart';

class ReportScreen extends StatefulWidget {
  final String initialType;
  const ReportScreen({super.key, required this.initialType});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _step = 1;
  bool _loading = false;
  bool _analyzing = false;

  Position? _location;
  XFile? _mediaFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  final TextEditingController _descriptionController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String? _uploadedMediaUrl;
  String? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _location = pos;
      });
    }
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    if (isVideo) {
      pickedFile = await picker.pickVideo(source: source);
    } else {
      pickedFile = await picker.pickImage(source: source);
    }

    if (pickedFile != null) {
      // If previous video controller exists, dispose it
      _videoController?.dispose();
      _videoController = null;

      setState(() {
        _mediaFile = pickedFile;
        _isVideo = isVideo;
      });

      if (isVideo) {
        _videoController = VideoPlayerController.file(File(_mediaFile!.path))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
            _videoController!.setLooping(true);
          });
      }
    }
  }

  final EmergencyService _emergencyService = EmergencyService();

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty && _mediaFile == null) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for location...')));
      return;
    }

    setState(() {
      _loading = true;
      _analyzing = true;
    });

    try {
      // 1. Upload Media to Cloudinary if available
      if (_mediaFile != null) {
        if (_isVideo) {
          _uploadedMediaUrl =
              await _cloudinaryService.uploadVideo(File(_mediaFile!.path));
        } else {
          _uploadedMediaUrl =
              await _cloudinaryService.uploadImage(File(_mediaFile!.path));
        }
        print("Uploaded Media URL: $_uploadedMediaUrl");
      }

      // 2. AI Analysis (optional, we can do it in parallel or before saving)
      final gemini = Provider.of<GeminiService>(context, listen: false);
      try {
        _aiAnalysis = await gemini.analyzeIncident(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : "Emergency: ${widget.initialType}",
            _mediaFile != null && !_isVideo ? _mediaFile : null);
      } catch (e) {
        _aiAnalysis = "Could not analyze incident due to network error.";
      }

      // 3. Save to Firestore
      final response = await _emergencyService.submitEmergencyReport(
        emergencyType: widget.initialType,
        description: _descriptionController.text,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        address:
            "Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}", // Simplified for now, can use geocoding later
        mediaUrls: _uploadedMediaUrl != null ? [_uploadedMediaUrl!] : [],
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _step = 2; // Success Screen
          });
        }
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _analyzing = false;
        });
      }
    }
  }

  Widget _buildMediaSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMediaOptionIcon(LucideIcons.camera, "Photo",
            () => _pickMedia(ImageSource.camera, false)),
        _buildMediaOptionIcon(LucideIcons.image, "Gallery",
            () => _pickMedia(ImageSource.gallery, false)),
        _buildMediaOptionIcon(LucideIcons.video, "Video",
            () => _pickMedia(ImageSource.camera, true)),
        _buildMediaOptionIcon(LucideIcons.film, "Files",
            () => _pickMedia(ImageSource.gallery, true)),
      ],
    );
  }

  Widget _buildMediaOptionIcon(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaFile == null) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.uploadCloud, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text("Select media using the buttons above",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isVideo &&
              _videoController != null &&
              _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else if (!_isVideo)
            Image.file(File(_mediaFile!.path),
                fit: BoxFit.contain, width: double.infinity)
          else
            const CircularProgressIndicator(color: Colors.white),

          // Remove Button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                _videoController?.dispose();
                _videoController = null;
                setState(() {
                  _mediaFile = null;
                  _isVideo = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 2) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Emergency'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.grey),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _location != null
                                ? Colors.blue.shade200
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.mapPin,
                              size: 16, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _location != null
                              ? "Location acquired: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}"
                              : "Acquiring GPS location...",
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Media Upload
                  const Text("Evidence (Photo/Video)",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 12),
                  _buildMediaSelectionButtons(),
                  const SizedBox(height: 16),
                  _buildMediaPreview(),
                  const SizedBox(height: 24),

                  // Description
                  const Text("Description",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Describe the situation...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFDC2626), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.alertTriangle,
                            size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "By submitting, you agree to share your current location and media with emergency responders. False reporting is a punishable offense.",
                            style: TextStyle(
                                color: Colors.amber.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_loading ||
                        (_descriptionController.text.isEmpty &&
                            _mediaFile == null))
                    ? null
                    : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(
                              _uploadedMediaUrl == null && _mediaFile != null
                                  ? "Uploading Media..."
                                  : (_analyzing
                                      ? "Analyzing..."
                                      : "Connecting..."),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.send),
                          SizedBox(width: 8),
                          Text("Request Help",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle,
                    size: 48, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text(
                "Responders Notified",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Help is on the way. Your location and incident details have been broadcast to nearby emergency teams.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              if (_uploadedMediaUrl != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text("Media uploaded securely",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (_aiAnalysis != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.sparkles,
                              size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text("AI Assessment",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiAnalysis!,
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.5),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Reset the form state because this screen is a tab
                    setState(() {
                      _step = 1;
                      _mediaFile = null;
                      _isVideo = false;
                      _videoController?.dispose();
                      _videoController = null;
                      _descriptionController.clear();
                      _uploadedMediaUrl = null;
                      _aiAnalysis = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Done",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
