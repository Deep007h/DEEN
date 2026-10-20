import '../../../metadata/domain/models/anime_detail.dart';
import 'source_match.dart';
import 'source_episode.dart';
import 'stream_variant.dart';

/// Abstract contract for stream source providers.
/// Connects "what the anime is" with "where it plays from" in a generic way.
abstract class StreamProvider {
  /// Unique identifier of the provider (e.g. 'demo', 'direct_url', 'jellyfin').
  String get id;

  /// User-facing display name.
  String get displayName;

  /// Map a metadata entry to this provider's catalog entry (may return several candidates).
  Future<List<SourceMatch>> findTitle(AnimeDetail anime);

  /// Episodes available from this provider for the match.
  Future<List<SourceEpisode>> episodes(SourceMatch match);

  /// Playable variants for one episode.
  Future<List<StreamVariant>> resolve(SourceEpisode episode);
}
