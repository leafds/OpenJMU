import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:extended_text/extended_text.dart';

import 'package:openjmu/constants/constants.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard(
    this.comment, {
    Key key,
  }) : super(key: key);

  TextStyle get subtitleStyle => TextStyle(color: Colors.grey, fontSize: suSetSp(18.0));
  TextStyle get rootTopicTextStyle => TextStyle(fontSize: suSetSp(18.0));
  TextStyle get rootTopicMentionStyle => TextStyle(color: Colors.blue, fontSize: suSetSp(18.0));
  Color get subIconColor => Colors.grey;

  Widget getCommentNickname(context) {
    return Row(
      children: <Widget>[
        Text(
          comment.fromUserName ?? comment.fromUserUid,
          style: TextStyle(fontSize: suSetSp(22.0)),
          textAlign: TextAlign.left,
        ),
        if (Constants.developerList.contains(comment.fromUserUid))
          Container(
            margin: EdgeInsets.only(left: suSetWidth(14.0)),
            child: DeveloperTag(
              padding: EdgeInsets.symmetric(
                horizontal: suSetWidth(8.0),
                vertical: suSetHeight(4.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget get getCommentInfo {
    String _commentTime = comment.commentTime;
    DateTime now = DateTime.now();
    if (int.parse(_commentTime.substring(0, 4)) == now.year) {
      _commentTime = _commentTime.substring(5, 16);
    }
    if (int.parse(_commentTime.substring(0, 2)) == now.month &&
        int.parse(_commentTime.substring(3, 5)) == now.day) {
      _commentTime = '${_commentTime.substring(5, 11)}';
    }
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.middle,
            child: Icon(
              Icons.access_time,
              color: Colors.grey,
              size: suSetWidth(16.0),
            ),
          ),
          TextSpan(text: ' $_commentTime　'),
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.middle,
            child: Icon(
              Icons.smartphone,
              color: Colors.grey,
              size: suSetWidth(16.0),
            ),
          ),
          TextSpan(text: ' ${comment.from}　'),
        ],
      ),
      style: subtitleStyle,
    );
  }

  Widget getCommentContent(context, Comment comment) {
    String content = comment.content;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                getExtendedText(context, content),
                getRootContent(context, comment),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget getRootContent(context, Comment comment) {
    var content = comment.toReplyContent ?? comment.toTopicContent;
    if (content != null && content.length > 0) {
      String topic;
      if (comment.toReplyExist) {
        topic = '<M ${comment.toReplyUid}>@${comment.toReplyUserName}<\/M> 的评论: ';
      } else {
        topic = '<M ${comment.toTopicUid}>@${comment.toTopicUserName}<\/M>: ';
      }
      topic += content;
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.all(suSetWidth(16.0)),
        padding: EdgeInsets.all(suSetWidth(10.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(suSetWidth(10.0)),
          color: Theme.of(context).canvasColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            getExtendedText(context, topic, isRoot: true),
          ],
        ),
      );
    } else {
      return getPostBanned();
    }
  }

  Widget getPostBanned() {
    return Container(
      color: currentThemeColor.withOpacity(0.4),
      margin: EdgeInsets.only(top: suSetHeight(10.0)),
      padding: EdgeInsets.all(suSetWidth(30.0)),
      child: Center(
        child: Text(
          '该条微博已被屏蔽或删除',
          style: TextStyle(
            color: Colors.white,
            fontSize: suSetSp(20.0),
          ),
        ),
      ),
    );
  }

  Widget getExtendedText(context, content, {isRoot}) {
    return Padding(
      padding:
          (isRoot ?? false) ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: suSetWidth(24.0)),
      child: ExtendedText(
        content != null ? '$content ' : null,
        style: TextStyle(fontSize: suSetSp(21.0)),
        onSpecialTextTap: specialTextTapRecognizer,
        maxLines: 8,
        overFlowTextSpan: OverFlowTextSpan(
          children: <TextSpan>[
            TextSpan(text: ' ...'),
            TextSpan(
              text: '全文',
              style: TextStyle(color: currentThemeColor),
            ),
          ],
        ),
        specialTextSpanBuilder: StackSpecialTextSpanBuilder(widgetType: WidgetType.comment),
      ),
    );
  }

  void confirmDelete(context) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: '删除评论',
      content: '是否确认删除这条评论?',
      showConfirm: true,
    );
    if (confirm) {
      final _loadingDialogController = LoadingDialogController();
      LoadingDialog.show(
        context,
        controller: _loadingDialogController,
        text: '正在删除评论',
        isGlobal: false,
      );
      CommentAPI.deleteComment(comment.post.id, comment.id).then((response) {
        _loadingDialogController.changeState('success', '评论删除成功');
        Instances.eventBus.fire(PostCommentDeletedEvent(comment.post.id));
      }).catchError((e) {
        debugPrint(e.toString());
        _loadingDialogController.changeState('failed', '评论删除失败');
      });
    }
  }

  void showAction(context) {
    if (comment.post != null) {
      ConfirmationBottomSheet.show(
        context,
        children: <Widget>[
          if (comment.fromUserUid == currentUser.uid || comment.post.uid == currentUser.uid)
            ConfirmationBottomSheetAction(
              text: '删除评论',
              icon: Icon(Icons.delete),
              onTap: () => confirmDelete(context),
            ),
          ConfirmationBottomSheetAction(
            text: '回复评论',
            icon: Icon(Icons.reply),
            onTap: () => navigatorState.pushNamed(
              Routes.OPENJMU_ADD_COMMENT,
              arguments: {'post': comment.post, 'comment': comment},
            ),
          ),
          ConfirmationBottomSheetAction(
            text: '查看动态',
            icon: Icon(Icons.pageview),
            onTap: () => navigatorState.pushNamed(
              Routes.OPENJMU_POST_DETAIL,
              arguments: {'post': comment.post, 'parentContext': context},
            ),
          ),
        ],
      );
    } else {
      ConfirmationDialog.show(context, title: '无可用操作', content: '该动态已被删除');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAction(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: suSetWidth(12.0),
          vertical: suSetHeight(6.0),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(suSetWidth(10.0)),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: suSetWidth(24.0),
                vertical: suSetHeight(12.0),
              ),
              child: Row(
                children: <Widget>[
                  UserAPI.getAvatar(size: 54.0, uid: comment.fromUserUid),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: suSetWidth(16.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          getCommentNickname(context),
                          separator(context, height: 4.0),
                          getCommentInfo,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            getCommentContent(context, comment),
          ],
        ),
      ),
    );
  }
}
