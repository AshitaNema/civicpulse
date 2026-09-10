import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'success_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _photo;
  bool _isLoading = false;
  String _loadingMessage = '';
  Position? _position;

  final GeminiService _geminiService = GeminiService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    } catch (_) {
      // Fallback gracefully if location cannot be obtained immediately
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open gallery: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a photo of the civic issue first.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Uploading photo...';
    });

    try {
      // 1. Upload photo to Storage (temp unique ID for storage path)
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final photoUrl = await _storageService.uploadPhoto(
        _photo!,
        tempId,
        type: 'before',
      );

      // 2. AI analysing issue via Gemini
      if (!mounted) return;
      setState(() {
        _loadingMessage = 'AI analysing issue...';
      });
      final classification = await _geminiService.classifyIssue(_photo!);

      // 3. Creating report in Firestore
      if (!mounted) return;
      setState(() {
        _loadingMessage = 'Creating report...';
      });

      final lat = _position?.latitude ?? 0.0;
      final lng = _position?.longitude ?? 0.0;
      final wardNumber = (lat.abs() * 10).toInt() % 10 + 1;
      final ward = 'Ward_$wardNumber';

      final reportData = {
        'photoUrl': photoUrl,
        'latitude': lat,
        'longitude': lng,
        'ward': ward,
        'issueType': classification['issueType'] ?? 'unknown',
        'severity': classification['severity'] ?? 'low',
        'confidence': classification['confidence'] ?? 0.0,
        'description': classification['description'] ?? 'Civic issue reported',
        'status': 'open',
        'isDuplicate': false,
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedResolution': null,
        'afterPhotoUrl': null,
      };

      final reportId = await _firestoreService.createReport(reportData);

      // Trigger Cloud Run Pub/Sub agent pipeline
      _firestoreService.triggerAgentPipeline(
        reportId,
        lat,
        lng,
        classification['issueType'] ?? 'unknown',
        ward,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });

      // 4. Navigate to SuccessScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SuccessScreen(reportId: reportId, classification: classification),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF1a1a2e);
    const accentBlue = Color(0xFF63b3ed);

    final locationText = _position != null
        ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
        : 'Detecting location...';

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Middle: Photo Capture Area
                  Expanded(
                    child: _photo == null
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213e),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentBlue.withValues(alpha: 0.6),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 64,
                                  color: accentBlue,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Add a photo of the issue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Potholes, garbage, lights, leaks, etc.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // ── Camera & Gallery buttons ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _photoSourceButton(
                                      icon: Icons.camera_alt_outlined,
                                      label: 'Camera',
                                      onTap: _pickFromCamera,
                                      accentColor: accentBlue,
                                    ),
                                    const SizedBox(width: 16),
                                    _photoSourceButton(
                                      icon: Icons.photo_library_outlined,
                                      label: 'Gallery',
                                      onTap: _pickFromGallery,
                                      accentColor: const Color(0xFFb794f4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _photo!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Retake row with both options
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _pickFromCamera,
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: accentBlue,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Camera',
                                      style: TextStyle(
                                        color: accentBlue,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      color: Color(0xFFb794f4),
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Gallery',
                                      style: TextStyle(
                                        color: Color(0xFFb794f4),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Location Display Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213e),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFe53e3e),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_position == null)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Submit Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        disabledBackgroundColor: accentBlue.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
