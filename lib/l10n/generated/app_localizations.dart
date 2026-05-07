import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
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
/// import 'generated/app_localizations.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hybrid Note App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get grocery;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @watchRead.
  ///
  /// In en, this message translates to:
  /// **'Watch/Read'**
  String get watchRead;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @languageFollowsDevice.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageFollowsDevice;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending Tasks'**
  String get pendingTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @journalEntries.
  ///
  /// In en, this message translates to:
  /// **'Journal Entries'**
  String get journalEntries;

  /// No description provided for @watchReadItems.
  ///
  /// In en, this message translates to:
  /// **'Watch/Read Items'**
  String get watchReadItems;

  /// No description provided for @groceryItems.
  ///
  /// In en, this message translates to:
  /// **'Grocery Items'**
  String get groceryItems;

  /// No description provided for @googleDriveSync.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @notSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet.'**
  String get notSyncedYet;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {date}'**
  String lastSynced(String date);

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @syncToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync to Google Drive'**
  String get syncToGoogleDrive;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allMyTasks.
  ///
  /// In en, this message translates to:
  /// **'All My Tasks'**
  String get allMyTasks;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @createCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get createCategoryTooltip;

  /// No description provided for @closeCategories.
  ///
  /// In en, this message translates to:
  /// **'Close categories'**
  String get closeCategories;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearTicked.
  ///
  /// In en, this message translates to:
  /// **'Clear Ticked'**
  String get clearTicked;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @addTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTaskTooltip;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @repeatEveryHowManyDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat every how many days?'**
  String get repeatEveryHowManyDays;

  /// No description provided for @reminderText.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {date}'**
  String reminderText(String date);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @noTasksHereYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks here yet.'**
  String get noTasksHereYet;

  /// No description provided for @tickedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ticked'**
  String tickedCount(int count);

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add Subtask'**
  String get addSubtask;

  /// No description provided for @editSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtask'**
  String get editSubtask;

  /// No description provided for @subtaskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Subtask title *'**
  String get subtaskTitleRequired;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @noSubtasksYet.
  ///
  /// In en, this message translates to:
  /// **'No subtasks yet.'**
  String get noSubtasksYet;

  /// No description provided for @subtaskProgress.
  ///
  /// In en, this message translates to:
  /// **'Subtasks: {completed}/{total}'**
  String subtaskProgress(int completed, int total);

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'{date} • repeats {repeat}'**
  String repeats(String date, String repeat);

  /// No description provided for @repeatsEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{date} • repeats every {days} day(s)'**
  String repeatsEveryDays(String date, int days);

  /// No description provided for @groceryList.
  ///
  /// In en, this message translates to:
  /// **'Grocery List'**
  String get groceryList;

  /// No description provided for @addGroceryItem.
  ///
  /// In en, this message translates to:
  /// **'Add Grocery Item'**
  String get addGroceryItem;

  /// No description provided for @addGroceryItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add grocery item'**
  String get addGroceryItemTooltip;

  /// No description provided for @editGroceryItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Grocery Item'**
  String get editGroceryItem;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @currentGroceryRun.
  ///
  /// In en, this message translates to:
  /// **'Current Grocery Run'**
  String get currentGroceryRun;

  /// No description provided for @nextTime.
  ///
  /// In en, this message translates to:
  /// **'Next Time'**
  String get nextTime;

  /// No description provided for @addAgainNextTime.
  ///
  /// In en, this message translates to:
  /// **'Add again to Next Time when completed'**
  String get addAgainNextTime;

  /// No description provided for @addAgainNextTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'The item will appear in Next Time after you clear/delete it from Current Grocery Run.'**
  String get addAgainNextTimeDescription;

  /// No description provided for @noGroceriesCurrent.
  ///
  /// In en, this message translates to:
  /// **'No groceries for this run yet.'**
  String get noGroceriesCurrent;

  /// No description provided for @noGroceriesNext.
  ///
  /// In en, this message translates to:
  /// **'No saved groceries for next time yet.'**
  String get noGroceriesNext;

  /// No description provided for @moveToCurrentRun.
  ///
  /// In en, this message translates to:
  /// **'Move to current run'**
  String get moveToCurrentRun;

  /// No description provided for @moveToNextTime.
  ///
  /// In en, this message translates to:
  /// **'Move to next time'**
  String get moveToNextTime;

  /// No description provided for @repeatsToNextTime.
  ///
  /// In en, this message translates to:
  /// **'Repeats to Next Time after clearing'**
  String get repeatsToNextTime;

  /// No description provided for @addJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Journal Entry'**
  String get addJournalEntry;

  /// No description provided for @addJournalEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add journal entry'**
  String get addJournalEntryTooltip;

  /// No description provided for @editJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Journal Entry'**
  String get editJournalEntry;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noJournalEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet.'**
  String get noJournalEntriesYet;

  /// No description provided for @watchReadList.
  ///
  /// In en, this message translates to:
  /// **'Watch/Read List'**
  String get watchReadList;

  /// No description provided for @addWatchReadItem.
  ///
  /// In en, this message translates to:
  /// **'Add Watch/Read Item'**
  String get addWatchReadItem;

  /// No description provided for @addWatchReadItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add watch/read item'**
  String get addWatchReadItemTooltip;

  /// No description provided for @editWatchReadItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Watch/Read Item'**
  String get editWatchReadItem;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @movie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get movie;

  /// No description provided for @tvShow.
  ///
  /// In en, this message translates to:
  /// **'TV Show'**
  String get tvShow;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @episode.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get episode;

  /// No description provided for @seasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonNumber(int number);

  /// No description provided for @episodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeNumber(int number);

  /// No description provided for @noWatchReadItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No watch/read items yet.'**
  String get noWatchReadItemsYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
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
