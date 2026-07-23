import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import 'locale_cubit.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final activeLanguageCode = Localizations.localeOf(context).languageCode;

    return Semantics(
      button: true,
      label: '${localizations.changeLanguage}: $activeLanguageCode',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: PopupMenuButton<String>(
          key: const Key('languageSwitcher'),
          tooltip: localizations.changeLanguage,
          icon: const Icon(Icons.language),
          onSelected: (languageCode) {
            context.read<LocaleCubit>().setLocale(Locale(languageCode));
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              key: const Key('englishLanguageOption'),
              value: 'en',
              child: _LanguageOption(
                label: localizations.englishLanguage,
                isSelected: activeLanguageCode == 'en',
              ),
            ),
            PopupMenuItem<String>(
              key: const Key('arabicLanguageOption'),
              value: 'ar',
              child: _LanguageOption(
                label: localizations.arabicLanguage,
                isSelected: activeLanguageCode == 'ar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: isSelected ? const Icon(Icons.check, size: 18) : null,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
