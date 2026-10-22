class AppLanguage {
  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
  AppLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  AppLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
  AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
  AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
];

String getLanguageDisplayName(String code) {
  final lang = kSupportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLanguage(code: code, name: code, nativeName: code),
  );
  return '${lang.name} (${lang.nativeName})';
}
