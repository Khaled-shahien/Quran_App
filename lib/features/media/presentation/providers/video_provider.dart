import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/media/domain/entities/video.dart';
import 'package:sakina_app/features/media/domain/entities/video_channel.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/usecases/get_islamic_videos.dart';

class VideoProvider extends ChangeNotifier {
  VideoProvider({required GetIslamicVideos getIslamicVideos})
    : _getIslamicVideos = getIslamicVideos;

  static const Map<String, String> categories = <String, String>{
    'خطب الجمعة': 'خطبة الجمعة',
    'دروس': 'درس ديني',
    'تفسير': 'تفسير القرآن',
    'قصص الأنبياء': 'قصص الأنبياء',
    'فقه': 'فقه إسلامي',
  };

  static const List<VideoChannel> fallbackChannels = <VideoChannel>[
    VideoChannel(
      name: 'قناة الرسالة',
      url: 'https://www.youtube.com/@alresala',
      description: 'برامج ودروس إسلامية',
    ),
    VideoChannel(
      name: 'دار الإفتاء المصرية',
      url: 'https://www.youtube.com/@DarAlIftaaMasriya',
      description: 'فتاوى ودروس شرعية',
    ),
    VideoChannel(
      name: 'الشيخ محمد متولي الشعراوي',
      url: 'https://www.youtube.com/@sharawy',
      description: 'تفسير القرآن الكريم',
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

    try {
      _videos = await _getIslamicVideos(_selectedQuery);
    } on MissingApiKeyException catch (error) {
      _videos = <Video>[];
      _fallbackMessage = error.message;
      _channels = fallbackChannels;
    } on QuotaExceededException catch (error) {
      _videos = <Video>[];
      _fallbackMessage = error.message;
      _channels = fallbackChannels;
    } catch (error) {
      _videos = <Video>[];
      _errorMessage = _messageFrom(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _messageFrom(Object error) {
    if (error is MediaException) return error.message;
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }
}
