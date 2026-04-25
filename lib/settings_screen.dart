import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/l10n/app_localizations.dart';

/// Settings screen for managing appearance and data.
/// Updated in V1.6.0 with the 'Premium Dark' collection.
class SettingsScreen extends StatelessWidget {
  final StorageService storage;
  final Function(Color? backgroundColor, List<Color>? blobColors, Decoration? decoration) onThemeChanged;

  const SettingsScreen({super.key, required this.storage, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeTitle = l10n?.settings ?? 'Appearance';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(themeTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const VisionBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 60, 16, 16),
            children: [
              _buildSectionTitle('PREMIUM DARK COLLECTION'),
              _buildOption(
                context,
                'Midnight (Default)',
                CupertinoIcons.moon_fill,
                () => onThemeChanged(AppColors.obsidianDark, [AppColors.accentBlue, AppColors.accentIndigo], null),
              ),
              _buildOption(
                context,
                'Deep Sea (Teal/Indigo)',
                CupertinoIcons.drop_fill,
                () => onThemeChanged(const Color(0xFF000814), [AppColors.accentTeal, AppColors.accentIndigo], null),
              ),
              _buildOption(
                context,
                'Cosmic (Purple/Indigo)',
                CupertinoIcons.sparkles,
                () => onThemeChanged(const Color(0xFF050015), [AppColors.accentPurple, AppColors.accentIndigo], null),
              ),
              _buildOption(
                context,
                'Cyber (Neon/Dark)',
                CupertinoIcons.bolt_fill,
                () => onThemeChanged(const Color(0xFF08080A), [AppColors.accentTeal, AppColors.accentPurple], null),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CLASSIC THEMES'),
              _buildOption(
                context,
                'Standard Vision',
                CupertinoIcons.circle_grid_hex_fill,
                () => onThemeChanged(null, null, null),
              ),
              _buildOption(
                context,
                'Sunset Bliss',
                CupertinoIcons.layers_fill,
                () => onThemeChanged(
                  null,
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
                          backgroundColor: AppColors.accentBlue,
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
                          backgroundColor: AppColors.accentBlue,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme applied: $title'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.accentBlue,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentBlue, size: 20, shadows: AppColors.iconShadows),
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
