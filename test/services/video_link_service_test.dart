// test/services/video_link_service_test.dart — 在线视频服务层单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moveon/services/database_service.dart';
import 'package:moveon/services/video_link_service.dart';
import 'package:moveon/models/online_video.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  /// 创建独立内存数据库并返回 (VideoLinkService, DatabaseService) 对
  Future<(VideoLinkService, DatabaseService)> _createService() async {
    final dbSvc = DatabaseService();
    await dbSvc.initialize(inMemory: true);
    return (VideoLinkService(dbService: dbSvc), dbSvc);
  }

  group('VideoLinkService - detectVideoType', () {
    test('detects .mp4 as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://example.com/video.mp4'),
        'direct',
      );
    });

    test('detects .webm as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://cdn.com/v.webm'),
        'direct',
      );
    });

    test('detects .mkv as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://host.com/movie.mkv'),
        'direct',
      );
    });

    test('detects .mov as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://site.com/clip.mov'),
        'direct',
      );
    });

    test('detects bilibili URL as link', () {
      expect(
        VideoLinkService.detectVideoType('https://www.bilibili.com/video/BV1xx411c7mD'),
        'link',
      );
    });

    test('detects general URL without video extension as link', () {
      expect(
        VideoLinkService.detectVideoType('https://youtube.com/watch?v=abc'),
        'link',
      );
    });
  });

  group('VideoLinkService - validateUrl', () {
    test('accepts valid https URL', () {
      expect(VideoLinkService.validateUrl('https://example.com/v.mp4'), isNull);
    });

    test('accepts valid http URL', () {
      expect(VideoLinkService.validateUrl('http://cdn.com/video.webm'), isNull);
    });

    test('rejects empty URL', () {
      expect(VideoLinkService.validateUrl(''), isNotNull);
    });

    test('rejects whitespace-only URL', () {
      expect(VideoLinkService.validateUrl('   '), isNotNull);
    });

    test('rejects ftp URL', () {
      expect(VideoLinkService.validateUrl('ftp://files.com/v.mp4'), isNotNull);
    });

    test('rejects string without protocol', () {
      expect(VideoLinkService.validateUrl('example.com/v.mp4'), isNotNull);
    });
  });

  group('VideoLinkService - validateTitle', () {
    test('accepts valid title', () {
      expect(VideoLinkService.validateTitle('晨间瑜伽'), isNull);
    });

    test('rejects empty title', () {
      expect(VideoLinkService.validateTitle(''), isNotNull);
    });

    test('rejects whitespace-only title', () {
      expect(VideoLinkService.validateTitle('   '), isNotNull);
    });

    test('rejects title over 50 chars', () {
      expect(VideoLinkService.validateTitle('一' * 51), isNotNull);
    });

    test('accepts title at exactly 50 chars', () {
      expect(VideoLinkService.validateTitle('一' * 50), isNull);
    });
  });

  group('VideoLinkService - CRUD', () {
    test('addVideo returns id and video can be retrieved', () async {
      final (svc, dbSvc) = await _createService();
      // 需要先创建用户以满足外键约束
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'vlink_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(
        userId: 1, category: '瑜伽',
        title: '晨间瑜伽', url: 'https://example.com/yoga.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      ));
      expect(id, greaterThan(0));

      final videos = await svc.getVideosForCategory(1, '瑜伽');
      expect(videos.length, 1);
      expect(videos.first.title, '晨间瑜伽');
      expect(videos.first.videoType, 'direct');
    });

    test('getVideosForCategory returns only matching category', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'cat_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      // 添加两个不同分类的视频
      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: '瑜伽A',
        url: 'https://x.com/a.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));
      await svc.addVideo(OnlineVideo(userId: 1, category: '有氧操', title: '有氧A',
        url: 'https://x.com/b.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 1)));

      final yogaVideos = await svc.getVideosForCategory(1, '瑜伽');
      expect(yogaVideos.length, 1);
      expect(yogaVideos.first.category, '瑜伽');

      final aeroVideos = await svc.getVideosForCategory(1, '有氧操');
      expect(aeroVideos.length, 1);
      expect(aeroVideos.first.category, '有氧操');
    });

    test('getVideosForCategory returns empty for no videos', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'empty_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final videos = await svc.getVideosForCategory(1, '冥想');
      expect(videos, isEmpty);
    });

    test('getVideosForCategory isolates per user', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'user_1', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      await db.insert('users', {
        'username': 'user_2', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      // 两个用户在同一分类下各自添加视频
      await svc.addVideo(OnlineVideo(userId: 1, category: '拉伸', title: 'U1视频',
        url: 'https://x.com/u1.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));
      await svc.addVideo(OnlineVideo(userId: 2, category: '拉伸', title: 'U2视频',
        url: 'https://x.com/u2.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 1)));

      final u1videos = await svc.getVideosForCategory(1, '拉伸');
      expect(u1videos.length, 1);
      expect(u1videos.first.title, 'U1视频');

      final u2videos = await svc.getVideosForCategory(2, '拉伸');
      expect(u2videos.length, 1);
      expect(u2videos.first.title, 'U2视频');
    });

    test('isDuplicateUrl returns true for same user+category+URL', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'dup_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: 'A',
        url: 'https://same-url.com/v.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));

      final dup = await svc.isDuplicateUrl(1, '瑜伽', 'https://same-url.com/v.mp4');
      expect(dup, true);
    });

    test('isDuplicateUrl returns false for different category same URL', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'diff_cat', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: 'A',
        url: 'https://url.com/v.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));

      final dup = await svc.isDuplicateUrl(1, '有氧操', 'https://url.com/v.mp4');
      expect(dup, false);
    });

    test('isDuplicateUrl with excludeId ignores self (edit scenario)', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'excl_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));

      // 排除自身——编辑时 URL 不变不应判重
      final dup = await svc.isDuplicateUrl(1, '体操', 'https://x.com/v.mp4', excludeId: id);
      expect(dup, false);
    });

    test('updateVideo modifies title, url, and videoType', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'update_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '塑形', title: '旧名',
        url: 'https://x.com/old.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));

      await svc.updateVideo(OnlineVideo(
        id: id, userId: 1, category: '塑形', title: '新名',
        url: 'https://x.com/new.webm', videoType: 'link',
        createdAt: DateTime(2026, 7, 18, 8, 0),
      ));

      final videos = await svc.getVideosForCategory(1, '塑形');
      expect(videos.first.title, '新名');
      expect(videos.first.url, 'https://x.com/new.webm');
      expect(videos.first.videoType, 'link');
    });

    test('deleteVideo removes video', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'delete_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '冥想', title: '删除我',
        url: 'https://x.com/del.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));

      await svc.deleteVideo(id);
      final videos = await svc.getVideosForCategory(1, '冥想');
      expect(videos, isEmpty);
    });

    test('videos returned in reverse chronological order', () async {
      final (svc, dbSvc) = await _createService();
      final db = await dbSvc.database;
      await db.insert('users', {
        'username': 'order_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      // 先添加"最早"，后添加"最晚"
      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: '最早',
        url: 'https://x.com/1.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0)));
      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: '最晚',
        url: 'https://x.com/2.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 9, 0)));

      final videos = await svc.getVideosForCategory(1, '瑜伽');
      expect(videos.length, 2);
      // 最晚添加的在前
      expect(videos.first.title, '最晚');
      expect(videos.last.title, '最早');
    });
  });
}
