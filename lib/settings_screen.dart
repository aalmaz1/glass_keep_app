import 'package:flutter/material.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';

class SettingsScreen extends StatelessWidget {
  final Function(Color? color, Decoration? decoration) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const VisionBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 60, 16, 16),
            children: [
              _buildOption(
                context,
                'Standard Vision',
                Icons.auto_awesome,
                () => onThemeChanged(null, null),
              ),
              _buildOption(
                context,
                'Obsidian Dark',
                Icons.dark_mode,
                () => onThemeChanged(const Color(0xFF0A0A0C), null),
              ),
              _buildOption(
                context,
                'Soft Blue',
                Icons.color_lens,
                () => onThemeChanged(const Color(0xFFE3F2FD), null),
              ),
              _buildOption(
                context,
                'Gentle Green',
                Icons.eco,
                () => onThemeChanged(const Color(0xFFE8F5E9), null),
              ),
              _buildOption(
                context,
                'Sunset Gradient',
                Icons.gradient,
                () => onThemeChanged(
                  null,
                  const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                    ),
                  ),
                ),
              ),
              _buildOption(
                context,
                'Ocean Gradient',
                Icons.water,
                () => onThemeChanged(
                  null,
                  const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassButton(
        onTap: () {
          onTap();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appearance updated: $title'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.accentBlue,
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
