class RouteConstants {
  RouteConstants._();

  static const String splashPath = '/';
  static const String splashName = 'splash';

  static const String unknownPath = '/unknown';
  static const String unknownName = 'unknown';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String registerPath = '/register';
  static const String registerName = 'register';
  static const String homePath = '/home';
  static const String homeName = 'home';

  static const String groupsPath = '/home/groups';
  static const String groupsName = 'groups';
  static const String friendsPath = '/home/friends';
  static const String friendsName = 'friends';
  static const String activityPath = '/home/activity';
  static const String activityName = 'activity';
  static const String accountPath = '/home/account';
  static const String accountName = 'account';

  static const String createGroupPath = '/create-group';
  static const String createGroupName = 'create-group';

  static const String groupDetailPath = '/group-detail/:groupId';
  static const String groupDetailName = 'group-detail';

  static const String addGroupMembersPath = '/group-detail/:groupId/add-members';
  static const String addGroupMembersName = 'add-group-members';

  static const String groupChartsPath = '/group-detail/:groupId/charts';
  static const String groupChartsName = 'group-charts';

  static const String groupCategoryExpensesPath =
      '/group-detail/:groupId/charts/category/:category';
  static const String groupCategoryExpensesName = 'group-category-expenses';

  static const String groupWhiteboardPath = '/group-detail/:groupId/whiteboard';
  static const String groupWhiteboardName = 'group-whiteboard';

  static const String groupInviteLinkPath = '/group-detail/:groupId/invite-link';
  static const String groupInviteLinkName = 'group-invite-link';

  static const String groupBalancesPath = '/group-detail/:groupId/balances';
  static const String groupBalancesName = 'group-balances';

  static const String addFriendPath = '/add-friend';
  static const String addFriendName = 'add-friend';

  static const String addFriendSearchPath = '/add-friend/search';
  static const String addFriendSearchName = 'add-friend-search';

  static const String addFriendNewPath = '/add-friend/new';
  static const String addFriendNewName = 'add-friend-new';

  static const String groupSettingsPath = '/group-detail/:groupId/settings';
  static const String groupSettingsName = 'group-settings';

  static const String editGroupPath = '/group-detail/:groupId/edit';
  static const String editGroupName = 'edit-group';

  static const String accountSettingsPath = '/account/settings';
  static const String accountSettingsName = 'account-settings';

  static const String emailSettingsPath = '/account/email-settings';
  static const String emailSettingsName = 'account-email-settings';

  static const String accountSecurityPath = '/account/security';
  static const String accountSecurityName = 'account-security';

  static const String useBiometricsPath = '/account/security/use-biometrics';
  static const String useBiometricsName = 'use-biometrics';

  static const String appearancePath = '/account/appearance';
  static const String appearanceName = 'account-appearance';

  static const String friendCodePath = '/friend-code';
  static const String friendCodeName = 'friend-code';

  static const String friendDetailPath = '/friend-detail/:friendId';
  static const String friendDetailName = 'friend-detail';

  static const String friendSettingsPath = '/friend-detail/:friendId/settings';
  static const String friendSettingsName = 'friend-settings';

  static const String addExpensePath = '/add-expense';
  static const String addExpenseName = 'add-expense';

  static const String friendRecordPaymentPath =
      '/friend-detail/:friendId/record-payment';
  static const String friendRecordPaymentName = 'friend-record-payment';

  static const String expenseDetailPath = '/expense-detail/:expenseId';
  static const String expenseDetailName = 'expense-detail';
}
