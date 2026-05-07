// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '混合笔记';

  @override
  String get home => '首页';

  @override
  String get tasks => '任务';

  @override
  String get grocery => '购物';

  @override
  String get journal => '日记';

  @override
  String get watchRead => '观看/阅读';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get languageFollowsDevice => '使用设备语言';

  @override
  String get switchToDarkMode => '切换到深色模式';

  @override
  String get switchToLightMode => '切换到浅色模式';

  @override
  String get pendingTasks => '待办任务';

  @override
  String get completedTasks => '已完成任务';

  @override
  String get journalEntries => '日记条目';

  @override
  String get watchReadItems => '观看/阅读项目';

  @override
  String get groceryItems => '购物项目';

  @override
  String get googleDriveSync => 'Google 云端硬盘同步';

  @override
  String get syncing => '正在同步...';

  @override
  String get notSyncedYet => '尚未同步。';

  @override
  String lastSynced(String date) {
    return '上次同步：$date';
  }

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get logOut => '退出登录';

  @override
  String get syncToGoogleDrive => '同步到 Google 云端硬盘';

  @override
  String get categories => '分类';

  @override
  String get allMyTasks => '全部任务';

  @override
  String get createCategory => '创建分类';

  @override
  String get createCategoryTooltip => '创建分类';

  @override
  String get closeCategories => '关闭分类';

  @override
  String get deleteCategory => '删除分类';

  @override
  String get category => '分类';

  @override
  String get categoryName => '分类名称';

  @override
  String get create => '创建';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get clear => '清除';

  @override
  String get clearTicked => '清除已勾选';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get add => '添加';

  @override
  String get addTask => '添加任务';

  @override
  String get addTaskTooltip => '添加任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get titleRequired => '标题 *';

  @override
  String get title => '标题';

  @override
  String get notes => '备注';

  @override
  String get setReminder => '设置提醒';

  @override
  String get date => '日期';

  @override
  String get time => '时间';

  @override
  String get repeat => '重复';

  @override
  String get doesNotRepeat => '不重复';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get custom => '自定义';

  @override
  String get repeatEveryHowManyDays => '每隔多少天重复？';

  @override
  String reminderText(String date) {
    return '提醒：$date';
  }

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get later => '之后';

  @override
  String get noTasksHereYet => '这里还没有任务。';

  @override
  String tickedCount(int count) {
    return '已勾选 $count 项';
  }

  @override
  String get addSubtask => '添加子任务';

  @override
  String get editSubtask => '编辑子任务';

  @override
  String get subtaskTitleRequired => '子任务标题 *';

  @override
  String get subtasks => '子任务';

  @override
  String get noSubtasksYet => '还没有子任务。';

  @override
  String subtaskProgress(int completed, int total) {
    return '子任务：$completed/$total';
  }

  @override
  String repeats(String date, String repeat) {
    return '$date • 重复：$repeat';
  }

  @override
  String repeatsEveryDays(String date, int days) {
    return '$date • 每 $days 天重复';
  }

  @override
  String get groceryList => '购物清单';

  @override
  String get addGroceryItem => '添加购物项目';

  @override
  String get addGroceryItemTooltip => '添加购物项目';

  @override
  String get editGroceryItem => '编辑购物项目';

  @override
  String get description => '描述';

  @override
  String get section => '区域';

  @override
  String get currentGroceryRun => '本次购物';

  @override
  String get nextTime => '下次';

  @override
  String get addAgainNextTime => '完成后再次加入下次';

  @override
  String get addAgainNextTimeDescription => '从本次购物清除/删除后，该项目会出现在下次。';

  @override
  String get noGroceriesCurrent => '本次购物还没有项目。';

  @override
  String get noGroceriesNext => '下次还没有保存的项目。';

  @override
  String get moveToCurrentRun => '移到本次购物';

  @override
  String get moveToNextTime => '移到下次';

  @override
  String get repeatsToNextTime => '清除后会重复到下次';

  @override
  String get addJournalEntry => '添加日记';

  @override
  String get addJournalEntryTooltip => '添加日记';

  @override
  String get editJournalEntry => '编辑日记';

  @override
  String get entry => '正文';

  @override
  String get close => '关闭';

  @override
  String get noJournalEntriesYet => '还没有日记。';

  @override
  String get watchReadList => '观看/阅读清单';

  @override
  String get addWatchReadItem => '添加观看/阅读项目';

  @override
  String get addWatchReadItemTooltip => '添加观看/阅读项目';

  @override
  String get editWatchReadItem => '编辑观看/阅读项目';

  @override
  String get type => '类型';

  @override
  String get status => '状态';

  @override
  String get movie => '电影';

  @override
  String get tvShow => '电视剧';

  @override
  String get book => '书';

  @override
  String get planned => '计划中';

  @override
  String get inProgress => '进行中';

  @override
  String get completed => '已完成';

  @override
  String get season => '季';

  @override
  String get episode => '集';

  @override
  String seasonNumber(int number) {
    return '第 $number 季';
  }

  @override
  String episodeNumber(int number) {
    return '第 $number 集';
  }

  @override
  String get noWatchReadItemsYet => '还没有观看/阅读项目。';
}
