// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for it.
class AppLocalizationsIT extends AppLocalizations {
  AppLocalizationsIT([String locale = 'it']) : super(locale);

  @override
  String get appTitle => "ProductChat Studio";

  @override
  String get smartAnalysis => "Analisi intelligente";

  @override
  String get uploadPrompt => "Carica un’immagine del prodotto per iniziare";
}
