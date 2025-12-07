class VersionCheck {
  final bool updateRequired;
  final bool updateAvailable;
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? message;
  final String? updateUrl;

  VersionCheck({
    required this.updateRequired,
    required this.updateAvailable,
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.message,
    this.updateUrl,
  });

  factory VersionCheck.fromJson(Map<String, dynamic> json) {
    return VersionCheck(
      updateRequired: json['update_required'] as bool? ?? false,
      updateAvailable: json['update_available'] as bool? ?? false,
      minVersion: json['min_version'] as String,
      latestVersion: json['latest_version'] as String,
      forceUpdate: json['force_update'] as bool? ?? false,
      message: json['message'] as String?,
      updateUrl: json['update_url'] as String?,
    );
  }
}

