import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Function(Color? color, Decoration? decoration) onThemeChanged;

  const SettingsScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки фона'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          _buildOption(
            context,
            'Стандартный',
            Icons.home,
            () => onThemeChanged(null, null),
          ),
          _buildOption(
            context,
            'Темная тема',
            Icons.dark_mode,
            () => onThemeChanged(const Color(0xFF121212), null),
          ),
          _buildOption(
            context,
            'Мягкий синий',
            Icons.color_lens,
            () => onThemeChanged(const Color(0xFFE3F2FD), null),
          ),
          _buildOption(
            context,
            'Нежный зеленый',
            Icons.eco,
            () => onThemeChanged(const Color(0xFFE8F5E9), null),
          ),
          _buildOption(
            context,
            'Градиент (Закат)',
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
            'Градиент (Океан)',
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
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onTap();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Фон изменен: $title'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.teal,
          ),
        );
      },
    );
  }
}
