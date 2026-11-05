import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/media/domain/entities/video.dart';
import 'package:sakina_app/features/media/domain/entities/video_channel.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/usecases/get_islamic_videos.dart';

class VideoProvider extends ChangeNotifier {
  VideoProvider({required GetIslamicVideos getIslamicVideos})
    : _getIslamicVideos = getIslamicVideos;

  static final Map<String, String> categories = <String, String>{
    appL10n.videoCategoryLabel1: appL10n.videoProviderMessage1,
    appL10n.videoCategoryLabel2: appL10n.videoProviderMessage2,
    appL10n.videoCategoryLabel3: appL10n.videoProviderMessage3,
    appL10n.videoCategoryLabel4: appL10n.videoProviderMessage4,
    appL10n.videoCategoryLabel5: appL10n.videoProviderMessage5,
  };

  static final List<VideoChannel> fallbackChannels = <VideoChannel>[
    VideoChannel(
      name: appL10n.videoProviderMessage6,
      url: 'https://www.youtube.com/@alresala',
      description: appL10n.videoProviderMessage7,
    ),
    VideoChannel(
      name: appL10n.videoProviderMessage8,
      url: 'https://www.youtube.com/@DarAlIftaaMasriya',
      description: appL10n.videoProviderMessage9,
    ),
    VideoChannel(
      name: appL10n.videoProviderMessage10,
      url: 'https://www.youtube.com/@sharawy',
      description: appL10n.videoProviderMessage11,
    ),
  ];

  final GetIslamicVideos _getIslamicVideos;

  List<Video> _videos = <Video>[];
  List<VideoChannel> _channels = <VideoChannel>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _fallbackMessage;
  String _selectedQuery = categories.values.first;

  List<Video> get videos => _videos;
  List<VideoChannel> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get fallbackMessage => _fallbackMessage;
  bool get hasError => _errorMessage != null;
  String get selectedQuery => _selectedQuery;

  Future<void> loadVideos([String? query]) async {
    _selectedQuery = query ?? _selectedQuery;
    _isLoading = true;
    _errorMessage = null;
    _fallbackMessage = null;
    _channels = <VideoChannel>[];
    notifyListeners();

    switch (await _getIslamicVideos(_selectedQuery)) {
      case Success(:final value):
        _videos = value;
      case Err(:final failure):
        _videos = <Video>[];
        switch (failure.cause) {
          // Without a key or quota, show the official channels instead.
          case MissingApiKeyException(:final message) ||
              QuotaExceededException(:final message):
            _fallbackMessage = message;
            _channels = fallbackChannels;
          case final cause:
            _errorMessage = _messageFrom(cause ?? failure);
        }
    }
    _isLoading = false;
    notifyListeners();
  }

  String _messageFrom(Object error) {
    if (error is MediaException) return error.message;
    return appL10n.articlesProviderMessage1;
  }
}
