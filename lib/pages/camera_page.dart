/// CameraPage - Live camera preview for capturing leaf images
/// 
/// This page provides:
/// - Live camera preview using the camera plugin
/// - Capture button to take a photo
/// - Option to pick image from gallery
/// - Guidance overlay to help frame the leaf
/// - Flash toggle control
/// - Camera flip (front/back) control
/// 
/// After capturing an image, navigates to ResultPage for analysis.

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'result_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  // Camera controller for managing camera operations
  CameraController? _cameraController;
  
  // List of available cameras on the device
  List<CameraDescription> _cameras = [];
  
  // Index of the currently selected camera (0 = back, 1 = front usually)
  int _selectedCameraIndex = 0;
  
  // Whether the camera is currently initializing
  bool _isInitializing = true;
  
  // Whether a capture is in progress
  bool _isCapturing = false;
  
  // Error message if camera fails
  String? _errorMessage;
  
  // Current flash mode
  FlashMode _flashMode = FlashMode.auto;
  
  // Image picker for gallery selection
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Register as observer to handle app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Initialize the camera when the page loads
    _checkPermissionsAndInitialize();
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    // Dispose camera controller to free resources
    _cameraController?.dispose();
    super.dispose();
  }

  /// Handle app lifecycle changes
  /// Pause camera when app is in background, resume when foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    
    // If camera isn't initialized, nothing to do
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // Free up resources when app is inactive
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize camera when app resumes
      _initializeCamera(_cameras[_selectedCameraIndex]);
    }
  }

  /// Check camera permissions and initialize if granted
  Future<void> _checkPermissionsAndInitialize() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });
    
    try {
      // On desktop platforms (Windows, Linux, macOS), permission_handler 
      // has limited support, so skip permission checks and go straight to camera
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await _setupCamera();
        return;
      }
      
      // On mobile platforms (Android, iOS), check current permission status first
      PermissionStatus cameraStatus = await Permission.camera.status;
      
      // If not determined yet or denied (but not permanently), show rationale and request
      if (cameraStatus.isDenied || cameraStatus.isRestricted) {
        // Show a dialog explaining why we need camera permission
        if (mounted) {
          final shouldRequest = await _showPermissionRationaleDialog();
          if (!shouldRequest) {
            setState(() {
              _isInitializing = false;
              _errorMessage = 'Camera permission is required to scan plant leaves.';
            });
            return;
          }
        }
        
        // Request the permission
        cameraStatus = await Permission.camera.request();
      }
      
      if (cameraStatus.isGranted || cameraStatus.isLimited) {
        await _setupCamera();
      } else if (cameraStatus.isPermanentlyDenied) {
        // User permanently denied permission, guide them to settings
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Camera permission permanently denied.\nPlease enable it in Settings.';
        });
        // Show dialog to guide user to settings
        if (mounted) {
          _showSettingsDialog();
        }
      } else {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Camera permission denied.\nPlease grant camera access to scan leaves.';
        });
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to check permissions: $e';
      });
    }
  }

  /// Show a dialog explaining why camera permission is needed
  Future<bool> _showPermissionRationaleDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green),
              SizedBox(width: 12),
              Text('Camera Permission'),
            ],
          ),
          content: const Text(
            'PlantDoctor needs camera access to take photos of plant leaves and detect diseases.\n\n'
            'Please grant camera permission when prompted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show dialog to guide user to app settings
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 12),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Camera permission was denied. To use the plant scanner, please:\n\n'
            '1. Tap "Open Settings"\n'
            '2. Select "Permissions"\n'
            '3. Enable "Camera"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Setup camera by getting available cameras and initializing the first one
  Future<void> _setupCamera() async {
    try {
      // Get list of available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No cameras found on this device.';
        });
        return;
      }
      
      // Find the back camera (preferred for plant scanning)
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      
      // If no back camera found, use the first available camera
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }
      
      // Initialize the selected camera
      await _initializeCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to setup camera: $e';
      });
    }
  }

  /// Initialize a specific camera
  Future<void> _initializeCamera(CameraDescription camera) async {
    // Dispose existing controller if any
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    
    // Create new controller with high resolution for better ML inference
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high, // Good balance between quality and performance
      enableAudio: false,     // No audio needed for plant scanning
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.jpeg 
          : ImageFormatGroup.bgra8888,
    );
    
    try {
      // Initialize the controller
      await _cameraController!.initialize();
      
      // Set initial flash mode
      await _cameraController!.setFlashMode(_flashMode);
      
      // Lock orientation to portrait for consistent UI
      await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      _handleCameraException(e);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  /// Handle camera exceptions with user-friendly messages
  void _handleCameraException(CameraException e) {
    String message;
    switch (e.code) {
      case 'CameraAccessDenied':
        message = 'Camera access denied.\nPlease grant camera permission.';
        break;
      case 'CameraAccessDeniedWithoutPrompt':
        message = 'Camera access denied.\nPlease enable it in Settings.';
        break;
      case 'CameraAccessRestricted':
        message = 'Camera access is restricted on this device.';
        break;
      case 'AudioAccessDenied':
        message = 'Audio access denied (not required for this app).';
        break;
      default:
        message = 'Camera error: ${e.description ?? e.code}';
    }
    
    setState(() {
      _isInitializing = false;
      _errorMessage = message;
    });
  }

  /// Toggle flash mode between auto, on, and off
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      default:
        newMode = FlashMode.auto;
    }
    
    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      _showSnackBar('Failed to change flash mode');
    }
  }

  /// Get icon for current flash mode
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  /// Switch between front and back cameras
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showSnackBar('No other camera available');
      return;
    }
    
    setState(() {
      _isInitializing = true;
    });
    
    // Toggle camera index
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    
    // Initialize the new camera
    await _initializeCamera(_cameras[_selectedCameraIndex]);
  }

  /// Capture a photo from the camera
  Future<void> _captureImage() async {
    final controller = _cameraController;
    
    // Validate camera state
    if (controller == null || !controller.value.isInitialized) {
      _showSnackBar('Camera not ready');
      return;
    }
    
    if (_isCapturing) {
      return; // Already capturing
    }
    
    setState(() => _isCapturing = true);
    
    try {
      // Ensure flash mode is set
      await controller.setFlashMode(_flashMode);
      
      // Capture the image
      final XFile imageFile = await controller.takePicture();
      
      if (mounted) {
        // Store the captured image path in provider
        context.read<AppProvider>().setCapturedImagePath(imageFile.path);
        
        // Navigate to result page with the image path
        _navigateToResult(imageFile.path);
      }
    } on CameraException catch (e) {
      _showSnackBar('Failed to capture: ${e.description ?? e.code}');
    } catch (e) {
      _showSnackBar('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Pick an image from the gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,    // Limit size for better performance
        maxHeight: 1920,
        imageQuality: 90,  // Good quality while keeping file size reasonable
      );
      
      if (pickedFile != null && mounted) {
        // Store the picked image path in provider
        context.read<AppProvider>().setCapturedImagePath(pickedFile.path);
        
        // Navigate to result page
        _navigateToResult(pickedFile.path);
      }
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        _showSnackBar('Photo library access denied. Please grant permission in Settings.');
      } else {
        _showSnackBar('Failed to pick image: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  /// Navigate to the result page with the captured image
  void _navigateToResult(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultPage(imagePath: imagePath),
      ),
    );
  }

  /// Show a snackbar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Open app settings for permission management
  Future<void> _openSettings() async {
    // openAppSettings() is not supported on desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _showSnackBar('Please check camera permissions in your system settings.');
      return;
    }
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent app bar over the camera preview
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black38,
          ),
        ),
        title: const Text('Scan Leaf'),
        actions: [
          // Gallery button in app bar
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
            tooltip: 'Pick from gallery',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Build the main body content based on current state
  Widget _buildBody() {
    // Show loading state while initializing
    if (_isInitializing) {
      return _buildLoadingState();
    }
    
    // Show error state if initialization failed
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    // Show camera preview
    return _buildCameraPreview();
  }

  /// Build loading state UI
  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state UI with retry option
  Widget _buildErrorState() {
    final bool isPermissionError = _errorMessage?.contains('permission') ?? false;
    
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error message
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Retry button
                    ElevatedButton.icon(
                      onPressed: _checkPermissionsAndInitialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    
                    // Settings button (for permission errors)
                    if (isPermissionError) ...[
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Alternative: pick from gallery
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Or pick from gallery'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build camera preview with controls
  Widget _buildCameraPreview() {
    final controller = _cameraController;
    
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingState();
    }
    
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview - centered and scaled to fill
          Center(
            child: AspectRatio(
              aspectRatio: 1 / controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
          
          // Guidance overlay - helps user frame the leaf
          _buildGuidanceOverlay(),
          
          // Top controls (flash, switch camera)
          _buildTopControls(),
          
          // Bottom controls (gallery, capture, placeholder)
          _buildBottomControls(),
        ],
      ),
    );
  }

  /// Build the guidance overlay to help frame the leaf
  Widget _buildGuidanceOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withAlpha(153),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 48,
              color: Colors.white.withAlpha(153),
            ),
            const SizedBox(height: 8),
            Text(
              'Position leaf here',
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build top control bar (flash, camera switch)
  Widget _buildTopControls() {
    return Positioned(
      top: 100, // Below the app bar
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flash toggle
            _buildControlButton(
              icon: _getFlashIcon(),
              onPressed: _toggleFlash,
              tooltip: 'Flash: ${_flashMode.name}',
            ),
            
            // Camera switch (only show if multiple cameras)
            if (_cameras.length > 1)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onPressed: _switchCamera,
                tooltip: 'Switch camera',
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// Build the bottom controls (capture button, etc.)
  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(179),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _buildControlButton(
                icon: Icons.photo_library,
                onPressed: _pickFromGallery,
                tooltip: 'Gallery',
              ),
              
              // Capture button
              _buildCaptureButton(),
              
              // Placeholder for symmetry (or additional control)
              const SizedBox(width: 48, height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the large capture button
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: _isCapturing 
              ? Colors.grey.withAlpha(128)
              : Colors.white.withAlpha(77),
        ),
        child: _isCapturing
            ? const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              )
            : Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Build a control button for the camera UI
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
