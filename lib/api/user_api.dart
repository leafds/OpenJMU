import 'dart:io';

import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/widgets/user_avatar.dart';

UserInfo get currentUser => UserAPI.currentUser;

class UserAPI {
  const UserAPI._();

  static UserInfo currentUser = UserInfo();

  static List<Cookie> cookiesForJWGL;

  static Future<Response<T>> login<T>(Map<String, dynamic> params) async {
    return NetUtils.tokenDio.post<T>(API.login, data: params);
  }

  static Future<void> logout(BuildContext context) async {
    final bool confirm = await ConfirmationBottomSheet.show(
      context,
      title: '退出登录',
      showConfirm: true,
      content: '是否确认退出登录?',
    );
    if (confirm) {
      Instances.eventBus.fire(LogoutEvent());
    }
  }

  static UserTag createUserTag(Map<String, dynamic> tagData) => UserTag(
        id: tagData['id'] as int,
        name: tagData['tagname'] as String,
      );

  /// Update cache network image provider after avatar is updated.
  static int avatarLastModified = DateTime.now().millisecondsSinceEpoch;
  static Widget getAvatar({
    double size = 48.0,
    int uid,
    int t,
  }) {
    return UserAvatar(uid: uid ?? currentUser.uid, size: size, timestamp: t);
  }

  static ImageProvider getAvatarProvider({int uid, int t}) {
    return ExtendedNetworkImageProvider(
      '${API.userAvatar}'
      '?uid=${uid ?? currentUser.uid}'
      '&_t=${t ?? avatarLastModified}'
      '&size=f152',
      cache: true,
      retries: 1,
    );
  }

  static void updateAvatarProvider() {
    ExtendedNetworkImageProvider(
      '${API.userAvatar}'
      '?uid=${currentUser.uid}'
      '&size=f152'
      '&_t=$avatarLastModified',
    ).evict();
    ExtendedNetworkImageProvider(
      '${API.userAvatar}'
      '?uid=${currentUser.uid}'
      '&size=f640'
      '&_t=$avatarLastModified',
    ).evict();
    avatarLastModified = DateTime.now().millisecondsSinceEpoch;
  }

  static Future<dynamic> getUserInfo({int uid}) async {
    if (uid == null) {
      return currentUser;
    } else {
      return NetUtils.getWithCookieAndHeaderSet<dynamic>(
        API.userInfo,
        data: <String, dynamic>{'uid': uid},
      );
    }
  }

  static Future<Response<Map<String, dynamic>>> getStudentInfo({int uid}) async {
    return NetUtils.getWithCookieSet<Map<String, dynamic>>(
        API.studentInfo(uid: uid ?? currentUser.uid));
  }

  static Future getLevel(int uid) {
    return NetUtils.getWithCookieSet(API.userLevel(uid: uid));
  }

  static Future getTags(int uid) {
    return NetUtils.getWithCookieAndHeaderSet(API.userTags, data: {'uid': uid});
  }

  static Future getFans(int uid) {
    return NetUtils.getWithCookieAndHeaderSet('${API.userFans}$uid');
  }

  static Future getIdols(int uid) {
    return NetUtils.getWithCookieAndHeaderSet('${API.userIdols}$uid');
  }

  static Future getFansList(int uid, int page) {
    return NetUtils.getWithCookieAndHeaderSet(
      '${API.userFans}$uid/page/$page/page_size/20',
    );
  }

  static Future getIdolsList(int uid, int page) {
    return NetUtils.getWithCookieAndHeaderSet(
      '${API.userIdols}$uid/page/$page/page_size/20',
    );
  }

  static Future getFansAndFollowingsCount(int uid) {
    return NetUtils.getWithCookieAndHeaderSet('${API.userFansAndIdols}$uid');
  }

  static Future<Response<Map<String, dynamic>>> getNotifications() async =>
      NetUtils.getWithCookieAndHeaderSet<Map<String, dynamic>>(API.postUnread);

  static Future follow(int uid) async {
    try {
      await NetUtils.postWithCookieAndHeaderSet('${API.userRequestFollow}$uid');
      await NetUtils.postWithCookieAndHeaderSet(API.userFollowAdd, data: {'fid': uid, 'tagid': 0});
    } catch (e) {
      trueDebugPrint('Failed when folloe: $e');
      showCenterErrorToast('关注失败');
    }
  }

  static Future unFollow(int uid, {bool fromBlacklist = false}) async {
    try {
      await NetUtils.deleteWithCookieAndHeaderSet('${API.userRequestFollow}$uid');
      await NetUtils.postWithCookieAndHeaderSet(API.userFollowAdd, data: {'fid': uid});
    } catch (e) {
      trueDebugPrint('Failed when unfollow $uid: $e');
      if (!fromBlacklist) showCenterErrorToast('取消关注失败');
    }
  }

  static Future setSignature(content) async {
    return NetUtils.postWithCookieAndHeaderSet(
      API.userSignature,
      data: {'signature': content},
    );
  }

  static Future<Map<String, dynamic>> searchUser(String name) async {
    Map<String, dynamic> users = (await NetUtils.getWithCookieSet<Map<String, dynamic>>(
      API.searchUser,
      data: <String, dynamic>{'keyword': name},
    ))
        .data;
    if (users['total'] == null) {
      users = <String, dynamic>{
        'total': 1,
        'data': [users]
      };
    }
    return users;
  }

  /// Blacklists.
  static final Set<BlacklistUser> blacklist = <BlacklistUser>{};

  static Future<Response<Map<String, dynamic>>> getBlacklist({int pos, int size}) {
    return NetUtils.getWithCookieSet<Map<String, dynamic>>(
      API.blacklist(pos: pos, size: size),
    );
  }

  static void confirmBlock(BuildContext context, BlacklistUser user) async {
    final add = !UserAPI.blacklist.contains(user);
    final confirm = await ConfirmationDialog.show(
      context,
      title: '${add ? '加入' : '移出'}黑名单',
      content: '确定将此人${add ? '加入' : '移出'}黑名单吗?',
      showConfirm: true,
    );
    if (confirm) {
      if (add) {
        UserAPI.fAddToBlacklist(user);
      } else {
        UserAPI.fRemoveFromBlacklist(user);
      }
    }
  }

  static void fAddToBlacklist(BlacklistUser user) {
    if (blacklist.contains(user)) {
      showToast('仇恨值拉满啦！不要重复屏蔽噢~');
    } else {
      NetUtils.postWithCookieSet(API.addToBlacklist, data: {'fid': user.uid}).then((response) {
        blacklist.add(user);
        showToast('加入黑名单成功');
        Instances.eventBus.fire(BlacklistUpdateEvent());
        unFollow(user.uid, fromBlacklist: true);
      }).catchError((e) {
        showToast('加入黑名单失败');
        trueDebugPrint('Add $user to blacklist failed : $e');
      });
    }
  }

  static void fRemoveFromBlacklist(BlacklistUser user) {
    blacklist.remove(user);
    showToast('移出黑名单成功');
    Instances.eventBus.fire(BlacklistUpdateEvent());
    NetUtils.postWithCookieSet(API.removeFromBlacklist, data: {'fid': user.uid}).catchError((e) {
      showToast('移出黑名单失败');
      trueDebugPrint('Remove $user from blacklist failed: $e');
      if (blacklist.contains(user)) blacklist.remove(user);
      Instances.eventBus.fire(BlacklistUpdateEvent());
    });
  }

  static void setBlacklist(List<dynamic> list) {
    if (list.isNotEmpty) {
      for (final Map<dynamic, dynamic> person in list) {
        final BlacklistUser user = BlacklistUser.fromJson(person as Map<String, dynamic>);
        blacklist.add(user);
      }
    }
  }
}
