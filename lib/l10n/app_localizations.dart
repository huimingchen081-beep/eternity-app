import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Eternity'**
  String get appTitle;

  /// No description provided for @appTitleCN.
  ///
  /// In en, this message translates to:
  /// **'永生'**
  String get appTitleCN;

  /// No description provided for @universe.
  ///
  /// In en, this message translates to:
  /// **'Universe'**
  String get universe;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @recordNow.
  ///
  /// In en, this message translates to:
  /// **'Capture this moment...'**
  String get recordNow;

  /// No description provided for @unlockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Version'**
  String get unlockPrompt;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy USD 1.99'**
  String get buyNow;

  /// No description provided for @purchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Eternity'**
  String get purchaseTitle;

  /// No description provided for @purchaseDesc.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Record your memories forever in the universe.'**
  String get purchaseDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @planetMemory.
  ///
  /// In en, this message translates to:
  /// **'Planet Memory'**
  String get planetMemory;

  /// No description provided for @emptyPlanet.
  ///
  /// In en, this message translates to:
  /// **'No memories on this planet yet'**
  String get emptyPlanet;

  /// No description provided for @textMemory.
  ///
  /// In en, this message translates to:
  /// **'Text Memory'**
  String get textMemory;

  /// No description provided for @voiceMemory.
  ///
  /// In en, this message translates to:
  /// **'Voice Memory'**
  String get voiceMemory;

  /// No description provided for @imageMemory.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get imageMemory;

  /// No description provided for @videoMemory.
  ///
  /// In en, this message translates to:
  /// **'Video Memory'**
  String get videoMemory;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @litPlanets.
  ///
  /// In en, this message translates to:
  /// **'Lit Planets'**
  String get litPlanets;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @fullVersion.
  ///
  /// In en, this message translates to:
  /// **'Full Version'**
  String get fullVersion;

  /// No description provided for @freeVersion.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeVersion;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @anotherStar.
  ///
  /// In en, this message translates to:
  /// **'Another star lights up today ✨'**
  String get anotherStar;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Record this moment and let it live forever in the universe.'**
  String get reminderBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
