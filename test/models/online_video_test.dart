// test/models/online_video_test.dart — 在线视频模型单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/online_video.dart';

void main() {
  group('OnlineVideo model', () {
    // ---- fromMap: 从数据库行构造 (direct 类型) ----
    test('fromMap creates OnlineVideo with direct video_type', () {
      final map = {
        'id': 1,
        'user_id': 42,
        'category': '瑜伽',
        'title': '晨间瑜伽30分钟',
        'url': 'https://example.com/yoga.mp4',
        'video_type': 'direct',
        'created_at': '2026-07-18T08:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.id, 1);
      expect(video.userId, 42);
      expect(video.category, '瑜伽');
      expect(video.title, '晨间瑜伽30分钟');
      expect(video.url, 'https://example.com/yoga.mp4');
      expect(video.videoType, 'direct');
      expect(video.createdAt, DateTime(2026, 7, 18, 8, 0, 0));
    });

    // ---- fromMap: link 类型 ----
    test('fromMap creates OnlineVideo with link video_type', () {
      final map = {
        'id': 2,
        'user_id': 7,
        'category': '有氧操',
        'title': 'B站有氧操',
        'url': 'https://www.bilibili.com/video/BV1xx411c7mD',
        'video_type': 'link',
        'created_at': '2026-07-18T09:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.videoType, 'link');
    });

    // ---- fromMap: id 为 null（未写入数据库前） ----
    test('fromMap handles null id (pre-insert)', () {
      final map = {
        'user_id': 1,
        'category': '拉伸',
        'title': '拉伸',
        'url': 'https://example.com/stretch.mkv',
        'video_type': 'direct',
        'created_at': '2026-07-18T10:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.id, isNull);
    });

    // ---- toMap: 序列化不含 id（insert 时） ----
    test('toMap excludes id when null', () {
      final video = OnlineVideo(
        userId: 1,
        category: '普拉提',
        title: '普拉提基础',
        url: 'https://example.com/pilates.mp4',
        videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 11, 0, 0),
      );
      final map = video.toMap();
      expect(map.containsKey('id'), false);
      expect(map['user_id'], 1);
      expect(map['category'], '普拉提');
      expect(map['title'], '普拉提基础');
      expect(map['url'], 'https://example.com/pilates.mp4');
      expect(map['video_type'], 'direct');
      expect(map['created_at'], '2026-07-18T11:00:00.000');
    });

    // ---- toMap: 含 id（update 时） ----
    test('toMap includes id when not null', () {
      final video = OnlineVideo(
        id: 5, userId: 1, category: '冥想',
        title: '冥想引导', url: 'https://bilibili.com/video/123',
        videoType: 'link', createdAt: DateTime(2026, 7, 18, 12, 0, 0),
      );
      final map = video.toMap();
      expect(map['id'], 5);
    });

    // ---- copyWith: 部分字段更新 ----
    test('copyWith creates updated copy preserving other fields', () {
      final original = OnlineVideo(
        id: 1, userId: 42, category: '瑜伽',
        title: '旧标题', url: 'https://example.com/old.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      );
      final updated = original.copyWith(title: '新标题', url: 'https://example.com/new.mp4');
      expect(updated.id, 1);
      expect(updated.userId, 42);
      expect(updated.category, '瑜伽');
      expect(updated.title, '新标题');
      expect(updated.url, 'https://example.com/new.mp4');
      expect(updated.videoType, 'direct');
      expect(updated.createdAt, original.createdAt);
    });

    // ---- video_type 接受 direct 值 ----
    test('videoType accepts direct value', () {
      final video = OnlineVideo(
        userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v.mp4', videoType: 'direct',
        createdAt: DateTime.now(),
      );
      expect(video.videoType, 'direct');
    });

    // ---- video_type 接受 link 值 ----
    test('videoType accepts link value', () {
      final video = OnlineVideo(
        userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v', videoType: 'link',
        createdAt: DateTime.now(),
      );
      expect(video.videoType, 'link');
    });
  });
}
