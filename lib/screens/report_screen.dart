import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:resq_flutter/services/cloudinary_service.dart';
import 'package:resq_flutter/services/emergency_service.dart';
import 'package:resq_flutter/services/theme_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ReportScreen extends StatefulWidget {
  final String initialType;
  final String? preSelectedResponderId;
  const ReportScreen({super.key, required this.initialType, this.preSelectedResponderId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _step = 1;
  bool _loading = false;
  bool _analyzing = false; // true while Gemini is running — shown in UI

  Position? _location;
  XFile? _mediaFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  final TextEditingController _descriptionController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String? _uploadedMediaUrl;
  String? _aiAnalysis;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _initSpeech();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _listen() async {
    if (!_isListening) {
      if (_speechEnabled) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _descriptionController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descriptionController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _location = pos);
    }
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = isVideo ? await picker.pickVideo(source: source) : await picker.pickImage(source: source);

    if (pickedFile != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please wait for location...')));
      return;
    }

    setState(() {
      _loading = true;
      _analyzing = true;
    });

    try {
      if (_mediaFile != null) {
        _uploadedMediaUrl = _isVideo 
          ? await _cloudinaryService.uploadVideo(File(_mediaFile!.path))
          : await _cloudinaryService.uploadImage(File(_mediaFile!.path));
      }

      final gemini = Provider.of<GeminiService>(context, listen: false);
      try {
        _aiAnalysis = await gemini.analyzeIncident(
            _descriptionController.text.isNotEmpty ? _descriptionController.text : "Emergency: ${widget.initialType}",
            _mediaFile != null && !_isVideo ? _mediaFile : null);
      } catch (e) {
        _aiAnalysis = "Could not analyze incident due to network error.";
      }

      final response = await _emergencyService.submitEmergencyReport(
        emergencyType: widget.initialType,
        description: _descriptionController.text,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        address: "Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}",
        mediaUrls: _uploadedMediaUrl != null ? [_uploadedMediaUrl!] : [],
        preferredResponderId: widget.preSelectedResponderId,
        aiAnalysis: _aiAnalysis,
      );

      if (response['success'] == true) {
        if (mounted) setState(() => _step = 2);
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; _analyzing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 2) return _buildSuccessScreen();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(themeProvider.t('sos_instructions'), style: const TextStyle(fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
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
                  _buildLocationStatus(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Evidence (Photo/Video)", isDark),
                  const SizedBox(height: 12),
                  _buildMediaSelectionButtons(isDark),
                  const SizedBox(height: 16),
                  _buildMediaPreview(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Description", isDark),
                  const SizedBox(height: 8),
                  _buildDescriptionField(isDark),
                  const SizedBox(height: 24),
                  _buildWarningCard(isDark),
                ],
              ),
            ),
          ),
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLocationStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _location != null
                  ? "Location: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}"
                  : "Acquiring GPS location...",
              style: TextStyle(color: Colors.blue.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF334155)));
  }

  Widget _buildMediaSelectionButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMediaOptionIcon(LucideIcons.camera, "Photo", () => _pickMedia(ImageSource.camera, false), isDark),
        _buildMediaOptionIcon(LucideIcons.image, "Gallery", () => _pickMedia(ImageSource.gallery, false), isDark),
        _buildMediaOptionIcon(LucideIcons.video, "Video", () => _pickMedia(ImageSource.camera, true), isDark),
        _buildMediaOptionIcon(LucideIcons.film, "Files", () => _pickMedia(ImageSource.gallery, true), isDark),
      ],
    );
  }

  Widget _buildMediaOptionIcon(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF334155), size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: _mediaFile == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.camera, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text("Preview Evidence", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                _isVideo && _videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                    : Image.file(File(_mediaFile!.path), fit: BoxFit.cover),
                Positioned(
                  top: 10, right: 10,
                  child: IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                    onPressed: () => setState(() { _mediaFile = null; _videoController?.dispose(); _videoController = null; }),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: "Describe the emergency...",
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
        suffixIcon: IconButton(
          icon: Icon(_isListening ? LucideIcons.mic : LucideIcons.mic, color: _isListening ? Colors.red : Colors.grey),
          onPressed: _listen,
        ),
      ),
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text("False reporting is a punishable offense. Responders will see your location.", style: TextStyle(color: Colors.amber.shade800, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _loading ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _analyzing
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 12), Text("Analyzing with AI...", style: TextStyle(fontWeight: FontWeight.bold))])
            : _loading 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SEND EMERGENCY REQUEST", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.checkCircle, size: 64, color: Colors.green),
              ),
              const SizedBox(height: 32),
              const Text("Responders Notified!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.green)),
              const SizedBox(height: 16),
              const Text(
                "Your request has been broadcasted. Help is on the way. Stay calm and stay in your current location.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_aiAnalysis != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [Colors.purple.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.purple.withValues(alpha: 0.3) : Colors.purple.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.sparkles, size: 20, color: Colors.purple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "AI First Aid Assessment", 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                                color: isDark ? Colors.purple.shade200 : Colors.purple.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _aiAnalysis!, 
                        style: TextStyle(
                          height: 1.6, 
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "This summary was sent to the responder. Follow these steps until help arrives.",
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("I AM SAFE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
