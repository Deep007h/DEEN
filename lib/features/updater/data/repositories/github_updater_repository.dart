import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../domain/models/app_release_info.dart';

/// Abstract repository for querying app update information.
abstract class UpdaterRepository {
  Future<AppReleaseInfo?> getLatestRelease();
  Future<AppReleaseInfo?> checkForUpdate(String currentVersion);
}

/// GitHub Releases implementation of [UpdaterRepository].
/// Queries GitHub API for the DEEN repository releases.
class GithubUpdaterRepository implements UpdaterRepository {
  static const String defaultOwner = 'Deep007h';
  static const String defaultRepo = 'DEEN';

  final String owner;
  final String repo;
  final Dio _dio;

  GithubUpdaterRepository({
    this.owner = defaultOwner,
    this.repo = defaultRepo,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'DEEN-App-Updater',
                },
              ),
            );

  @override
  Future<AppReleaseInfo?> getLatestRelease() async {
    final endpoint = 'https://api.github.com/repos/$owner/$repo/releases';
    try {
      final response = await _dio.get<dynamic>(endpoint);

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        if (list.isEmpty) {
          developer.log('GitHub releases list is empty for $owner/$repo', name: 'GithubUpdaterRepository');
          return null;
        }

        // Find the latest published, non-draft release
        Map<String, dynamic>? selectedRelease;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final isDraft = item['draft'] as bool? ?? false;
            final isPrerelease = item['prerelease'] as bool? ?? false;
            if (!isDraft && !isPrerelease) {
              selectedRelease = item;
              break;
            }
          }
        }

        // If all are marked prerelease or draft, fallback to first item
        selectedRelease ??= list.first is Map<String, dynamic> ? list.first as Map<String, dynamic> : null;

        if (selectedRelease != null) {
          return AppReleaseInfo.fromJson(selectedRelease);
        }
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        developer.log('GitHub releases returned 404 for $owner/$repo', name: 'GithubUpdaterRepository');
      } else {
        developer.log('Network error checking GitHub releases: ${e.message}', name: 'GithubUpdaterRepository');
      }
      return null;
    } catch (e, stack) {
      developer.log('Unexpected error fetching GitHub releases: $e\n$stack', name: 'GithubUpdaterRepository');
      return null;
    }
  }

  @override
  Future<AppReleaseInfo?> checkForUpdate(String currentVersion) async {
    final latest = await getLatestRelease();
    if (latest == null) return null;

    final hasUpdate = AppReleaseInfo.isUpdateAvailable(currentVersion, latest.tagName);
    if (hasUpdate) {
      developer.log('Update found! Current: $currentVersion, Remote: ${latest.tagName}', name: 'GithubUpdaterRepository');
      return latest;
    }

    developer.log('App is up to date: $currentVersion vs remote: ${latest.tagName}', name: 'GithubUpdaterRepository');
    return null;
  }
}
