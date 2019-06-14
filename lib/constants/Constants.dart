import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:event_bus/event_bus.dart';

import 'package:OpenJMU/model/Bean.dart';

class Constants {
    static int homeSplashIndex = 0;

    static final String endLineTag = "没有更多了";

    // Fow news list.
    static final String newsApiKey = "c2bd7a89a377595c1da3d49a0ca825d5";

    // For posts. Different type of devices (iOS/Android) use different pair of key and secret.
    static final String postApiKeyAndroid = "1FD8506EF9FF0FAB7CAFEBB610F536A1";
    static final String postApiSecretAndroid = "E3277DE3AED6E2E5711A12F707FA2365";
    static final String postApiKeyIOS = "3E63F9003DF7BE296A865910D8DEE630";
    static final String postApiSecretIOS = "773958E5CFE0FF8252808C417A8ECCAB";

    static final EventBus eventBus = new EventBus();

    static Notifications notifications = Notifications(0, 0, 0, 0);

    static DecoratedBox separator(context) => DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).canvasColor),
        child: SizedBox(height: suSetSp(8.0)),
    );

    static Widget nightModeCover() => Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        bottom: 0.0,
        child: DecoratedBox(decoration: BoxDecoration(
            color: Color(0x44000000),
        )),
    );

    static double suSetSp(double size) => ScreenUtil.getInstance().setSp(size) * 2;
}