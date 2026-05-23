import 'friend_status.dart';

/// Represents a friend/social contact in the app.
class Friend {
  const Friend({
    required this.id,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String displayName;
  final FriendStatus status;
}
