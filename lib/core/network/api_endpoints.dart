class ApiEndpoints {
  // Configurable base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  // Configurable WebSocket URL (defaults to base domain if empty)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: '',
  );

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User endpoints
  static const String me = '/me';
  static const String usersSearch = '/users/search';
  static String searchUsers(String query) =>
      '/users/search?query=${Uri.encodeComponent(query)}';


  // Workspace endpoints
  static const String workspaces = '/workspaces';
  static String workspace(String id) => '/workspaces/$id';
  static String workspaceMembers(String id, {String? query}) =>
      query != null && query.trim().isNotEmpty
          ? '/workspaces/$id/members?query=${Uri.encodeComponent(query.trim())}'
          : '/workspaces/$id/members';
  static String workspaceMember(String workspaceId, String userId) =>
      '/workspaces/$workspaceId/members/$userId';
  static String workspaceInvitations(String id) => '/workspaces/$id/invitations';
  static String workspaceInvitation(String workspaceId, String invitationId) =>
      '/workspaces/$workspaceId/invitations/$invitationId';
  static String workspaceArchive(String id) => '/workspaces/$id/archive';
  static String workspaceTransferOwnership(String id) =>
      '/workspaces/$id/transfer-ownership';
  static String workspaceLeave(String id) => '/workspaces/$id/leave';

  // Global Invitation endpoints
  static const String invitationsAccept = '/invitations/accept';
  static const String invitationsDecline = '/invitations/decline';
  static const String invitationsPreviewPost = '/invitations/preview';
  static String invitationsPreview(String token) =>
      '/invitations/preview?token=$token';

  // Project endpoints
  static String workspaceProjects(String workspaceId) =>
      '/workspaces/$workspaceId/projects';
  static String project(String id) => '/projects/$id';
  static String projectArchive(String id) => '/projects/$id/archive';

  // Task endpoints
  static String projectTasks(String projectId) =>
      '/projects/$projectId/tasks';
  static String task(String id) => '/tasks/$id';
  static String taskStatus(String id) => '/tasks/$id/status';

  // Comment endpoints
  static String taskComments(String taskId) => '/tasks/$taskId/comments';
  static String comment(String id) => '/comments/$id';

  // Subtasks endpoints
  static String taskSubtasks(String taskId) => '/tasks/$taskId/subtasks';
  static String taskSubtask(String taskId, String subtaskId) =>
      '/tasks/$taskId/subtasks/$subtaskId';

  // Labels endpoints
  static String workspaceLabels(String workspaceId) =>
      '/workspaces/$workspaceId/labels';
  static String workspaceLabel(String workspaceId, String labelId) =>
      '/workspaces/$workspaceId/labels/$labelId';
  static String taskLabel(String taskId, String labelId) =>
      '/tasks/$taskId/labels/$labelId';

  // Chat endpoints
  static String workspaceChannels(String workspaceId) =>
      '/workspaces/$workspaceId/channels';
  static String workspaceDirectMessages(String workspaceId) =>
      '/workspaces/$workspaceId/channels/dm';
  static String channelMessages(String channelId, {int limit = 50}) =>
      '/channels/$channelId/messages?limit=$limit';
  static String channelSendMessage(String channelId) =>
      '/channels/$channelId/messages';
  static String channelRead(String channelId) =>
      '/channels/$channelId/read';
  static String channelDetails(String channelId) =>
      '/channels/$channelId';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Health
  static const String healthLive = '/health/live';
  static const String healthReady = '/health/ready';
}
