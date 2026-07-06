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

  static const String addFriendPath = '/add-friend';
  static const String addFriendName = 'add-friend';

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
}
