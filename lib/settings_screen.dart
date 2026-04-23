import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final StorageService storage;
  final Function(Color? color, Decoration? decoration) onThemeChanged;

  const SettingsScreen({super.key, required this.storage, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.appearance),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const VisionBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 60, 16, 16),
            children: [
              _buildSectionTitle(l10n.themes),
              _buildOption(
                context,
                'Standard Vision',
                CupertinoIcons.sparkles,
                () => onThemeChanged(null, null),
              ),
              _buildOption(
                context,
                'Obsidian Dark',
                CupertinoIcons.moon,
                () => onThemeChanged(const Color(0xFF0A0A0C), null),
              ),
              _buildOption(
                context,
                'Soft Blue',
                CupertinoIcons.color_filter,
                () => onThemeChanged(const Color(0xFFE3F2FD), null),
              ),
              _buildOption(
                context,
                'Gentle Green',
                CupertinoIcons.tree,
                () => onThemeChanged(const Color(0xFFE8F5E9), null),
              ),
              _buildOption(
                context,
                'Sunset Gradient',
                CupertinoIcons.layers,
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
                CupertinoIcons.drop,
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
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.dataManagement),
              _buildOption(
                context,
                l10n.exportBackup,
                Icons.upload_file,
                () async {
                  try {
                    await storage.exportNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.exportSuccess), backgroundColor: AppColors.accentBlue),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: AppColors.accentRed),
                      );
                    }
                  }
                },
                popOnTap: false,
              ),
              _buildOption(
                context,
                l10n.importBackup,
                Icons.download,
                () async {
                  try {
                    await storage.importNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.importSuccess), backgroundColor: AppColors.accentBlue),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.importError}: $e'), backgroundColor: AppColors.accentRed),
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
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
                content: Text('Appearance updated: $title'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.accentBlue,
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
              size: 20,
              shadows: AppColors.iconShadows,
            ),
          ],
        ),
      ),
    );
  }
}
