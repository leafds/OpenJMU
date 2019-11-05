import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/pages/user/UserPage.dart';
import 'package:OpenJMU/widgets/cards/PostCard.dart';

class SearchPage extends StatefulWidget {
  final String content;

  SearchPage({this.content});

  @override
  State<StatefulWidget> createState() => SearchPageState();

  static void search(BuildContext context, String content) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
      return SearchPage(content: content);
    }));
  }
}

class SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  final FocusNode _focusNode = FocusNode();
  TextEditingController _controller = TextEditingController();

  List<User> userList;
  List<Post> postList;

  bool _loaded = false,
      _loading = false,
      _canLoadMore = true,
      _canClear = false,
      _autoFocus = true;

  @override
  void initState() {
    _controller.addListener(() {
      _canClear = _controller.text.length > 0;
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (widget.content != null) {
      _autoFocus = false;
      _controller = TextEditingController(text: widget.content);
      search(context, widget.content);
    }
    super.didChangeDependencies();
  }

  @override
  bool get wantKeepAlive => true;

  Future getPost(String searchQuery) async {
    bool loadMore = false;
    if (postList != null && postList.length > 0) {
      loadMore = true;
    }
    await PostAPI.getPostList(
      "search",
      false,
      loadMore,
      loadMore ? postList.last.id : 0,
      additionAttrs: {'words': searchQuery},
    ).then((response) {
      List _ps = response.data['topics'];
      if (_ps.length == 0) _canLoadMore = false;
      _ps.forEach((post) {
        Post p = Post.fromJson(post['topic']);
        if (postList == null) postList = [];
        postList.add(p);
      });
    });
  }

  void search(context, String content, {bool isMore = false}) {
    _focusNode.unfocus();
    _loading = true;
    if (!isMore) {
      _loaded = false;
      _canLoadMore = true;
      userList = null;
      postList = null;
      if (mounted) setState(() {});
    }
    Future.wait([
      if (!_loaded)
        UserAPI.searchUser(content).then((response) {
          List _us = response['data'];
          _us.forEach((user) {
            User u = User.fromJson(user);
            if (userList == null) userList = [];
            userList.add(u);
          });
        }),
      getPost(content)
    ]).then((responses) {
      if (!_loaded) _loaded = true;
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget searchTextField(context, {String content}) {
    if (content != null) {
      _controller = TextEditingController(text: content);
    }
    return Container(
      height: kToolbarHeight / 1.3,
      padding: EdgeInsets.only(
        left: Constants.suSetSp(16.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kToolbarHeight / 2),
        color: Theme.of(context).canvasColor,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              child: TextField(
                autofocus: _autoFocus && !_loaded,
                controller: _controller,
                cursorColor: ThemeUtils.currentThemeColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: "输入要搜索的内容...",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
                focusNode: _focusNode,
                keyboardType: TextInputType.text,
                style: Theme.of(context).textTheme.title.copyWith(
                      fontSize: Constants.suSetSp(20.0),
                      fontWeight: FontWeight.normal,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                textInputAction: TextInputAction.search,
                onSubmitted: (String text) {
                  if (!_loaded) _loaded = true;
                  if (text != null && text != "") {
                    search(context, text);
                  } else {
                    return null;
                  }
                },
              ),
            ),
          ),
          if (_canClear)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.suSetSp(16.0),
                ),
                child: Icon(
                  Icons.clear,
                  size: Constants.suSetSp(24.0),
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              onTap: () {
                _controller.clear();
                FocusScope.of(context).requestFocus(_focusNode);
              },
            )
        ],
      ),
    );
  }

  Widget userListView(context) {
    if (userList == null || userList.isEmpty) return SizedBox.shrink();
    return SizedBox(
      height: Constants.suSetSp(140.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: Constants.suSetSp(16.0),
              left: 12.0,
            ),
            child: Text(
              "相关用户 (${userList.length})",
              style: Theme.of(context).textTheme.caption.copyWith(
                    fontSize: Constants.suSetSp(16.0),
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: Constants.suSetSp(48.0),
                        height: Constants.suSetSp(48.0),
                        child: GestureDetector(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(Constants.suSetSp(24.0)),
                            child: FadeInImage(
                              fadeInDuration: const Duration(milliseconds: 100),
                              placeholder:
                                  AssetImage("assets/avatar_placeholder.png"),
                              image: UserAPI.getAvatarProvider(
                                uid: userList[index].id,
                              ),
                            ),
                          ),
                          onTap: () => UserPage.jump(
                            context,
                            userList[index].id,
                          ),
                        ),
                      ),
                      SizedBox(height: Constants.suSetSp(8.0)),
                      Text(
                        userList[index].nickname,
                        style: Theme.of(context).textTheme.body1.copyWith(
                              fontSize: Constants.suSetSp(16.0),
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1.0),
        ],
      ),
    );
  }

  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: searchTextField(context),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text != null && _controller.text != "") {
                      search(context, _controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: !_loading
          ? _loaded
              ? postList != null && postList.isNotEmpty
                  ? ListView.builder(
                      itemCount: postList.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return userListView(context);
                        } else if (index == 1) {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: Constants.suSetSp(16.0),
                              left: 12.0,
                            ),
                            child: Text(
                              "相关动态",
                              style:
                                  Theme.of(context).textTheme.caption.copyWith(
                                        fontSize: Constants.suSetSp(16.0),
                                      ),
                            ),
                          );
                        } else if (index == postList.length - 1) {
                          if (_canLoadMore)
                            search(
                              context,
                              _controller.text,
                              isMore: true,
                            );
                          return PostCard(
                            postList[index - 2],
                            isDetail: false,
                            parentContext: context,
                          );
                        } else if (index == postList.length) {
                          return SizedBox(
                            height: Constants.suSetSp(50.0),
                            child: Center(
                              child: Text(Constants.endLineTag),
                            ),
                          );
                        } else {
                          return PostCard(
                            postList[index - 2],
                            isDetail: false,
                            parentContext: context,
                          );
                        }
                      },
                    )
                  : SizedBox(
                      height: 300.0,
                      child: Center(
                        child: Text(
                          "没有搜索到动态内容~\n🧐",
                          style: TextStyle(
                            fontSize: Constants.suSetSp(24.0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
              : SizedBox.shrink()
          : Center(child: Constants.progressIndicator()),
    );
  }
}