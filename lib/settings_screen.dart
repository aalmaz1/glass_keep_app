import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/providers.dart';

/// Settings screen for managing appearance and data.
/// Updated in V1.7.0 with curated theme collections.
class SettingsScreen extends StatelessWidget {
  final StorageService storage;
  final Function(Color? backgroundColor, List<Color>? blobColors, Color? accentColor) onThemeChanged;

  const SettingsScreen({super.key, required this.storage, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appearanceTitle = l10n?.appearance ?? 'Appearance';
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.accentDeepPurple;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(appearanceTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: VisionBackground(
              backgroundColor: themeColor,
              blobColors: provider?.blobColors,
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 60, 16, 16),
            children: [
              _buildSectionTitle(l10n?.appearance ?? 'APPEARANCE'),
              const SizedBox(height: 8),
              _buildThemeSelector(context),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n?.dataManagement ?? 'DATA MANAGEMENT'),
              _buildOption(
                context,
                l10n?.exportBackup ?? 'Export Backup',
                Icons.upload_file,
                () async {
                  try {
                    await storage.exportNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.exportSuccess ?? 'Exported successfully'),
                          backgroundColor: AppColors.accentDeepPurple,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n?.exportError ?? 'Export error'}: $e'),
                          backgroundColor: AppColors.accentRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                popOnTap: false,
              ),
              _buildOption(
                context,
                l10n?.importBackup ?? 'Import Backup',
                Icons.download,
                () async {
                  try {
                    await storage.importNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.importSuccess ?? 'Imported successfully'),
                          backgroundColor: AppColors.accentDeepPurple,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n?.importError ?? 'Import error'}: $e'),
                          backgroundColor: AppColors.accentRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                popOnTap: false,
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Glass Keep ${AppColors.appVersion}',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final currentThemeColor = GlassAnimationProvider.of(context)?.themeColor;

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppThemes.all.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final theme = AppThemes.all[index];
          final isSelected = currentThemeColor == theme.backgroundColor;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                onThemeChanged(theme.backgroundColor, theme.blobColors, theme.accentColor);
              },
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? theme.accentColor : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          // Background color
                          Container(color: theme.backgroundColor),
                          // Gradient blobs preview
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.blobColors[0].withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            left: -10,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.blobColors[1].withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          // Glass card preview
                          Center(
                            child: Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool popOnTap = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassButton(
        onTap: () {
          onTap();
          if (popOnTap) {
            Navigator.pop(context);
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentDeepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentDeepPurple, size: 20, shadows: AppColors.iconShadows),
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
              CupertinoIcons.chevron_right,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
