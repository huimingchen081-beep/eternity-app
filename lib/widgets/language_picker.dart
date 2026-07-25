import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LanguagePicker extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguagePicker({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  static void show(BuildContext context, String currentLang, Function(String) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xEE0D0D2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LanguagePicker(
        currentLanguage: currentLang,
        onLanguageChanged: (lang) {
          onChanged(lang);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Language / 选择语言',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppConstants.supportedLanguages.length,
              itemBuilder: (context, index) {
                final lang = AppConstants.supportedLanguages[index];
                final code = lang['code']!;
                final name = lang['name']!;
                final flag = lang['flag']!;
                final isSelected = code == currentLanguage;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4FC3F7)
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF4FC3F7))
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor:
                      isSelected ? const Color(0x224FC3F7) : Colors.transparent,
                  onTap: () => onLanguageChanged(code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
