import 'package:flutter/widgets.dart';
import 'package:life_os/l10n/generated/app_localizations.dart';

/// Lets every widget write `context.l10n.someKey` instead of the more
/// verbose `AppLocalizations.of(context)!.someKey`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// True when the active locale is Arabic — occasionally useful for the
  /// handful of places that need locale-specific *logic* (not just text),
  /// e.g. choosing which digits to render in a big timer display.
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}
