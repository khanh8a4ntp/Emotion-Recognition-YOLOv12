import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/ic_launcher.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 40,
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'EVision',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD8BFD8), // Màu hồng nhạt từ logo
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD8BFD8), // Màu hồng nhạt từ logo
              Color(0xFF87CEEB), // Màu xanh lam nhạt từ logo
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Welcome to EVision',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Explore emotions through images, videos, and real-time detection',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavigationButton(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Image Picker',
                      route: '/image_picker',
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationButton(
                      context: context,
                      icon: Icons.video_library,
                      label: 'Video Picker',
                      route: '/video_picker',
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationButton(
                      context: context,
                      icon: Icons.camera,
                      label: 'Camera Capture',
                      route: '/camera_capture',
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationButton(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Real-time Detection',
                      route: '/realtime_detection',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE6E6FA), // Màu lavender nhạt
              Color(0xFFB0E0E6), // Màu xanh lam nhạt hơn
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.black, width: 2), // Thêm viền đen
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF4B0082), // Màu tím đậm để tăng độ tương phản
              size: 30,
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2526), // Màu xám đậm để tăng độ tương phản
              ),
            ),
          ],
        ),
      ),
    );
  }
}