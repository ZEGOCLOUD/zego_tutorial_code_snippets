// Package imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

// Project imports:
import 'constants.dart';

/// local virtual login
Future<void> login({
  required String userID,
  required String userName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(cacheUserIDKey, userID);

  currentUser.id = userID;
  currentUser.name = 'user_$userID';
}

/// local virtual logout
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove(cacheUserIDKey);
}

/// on user login
void onUserLogin() {
  /// 4/5. initialized ZegoUIKitPrebuiltCallInvitationService when account is logged in or re-logged in
  ZegoUIKitPrebuiltCallInvitationService().init(
    appID:  /*input your AppID*/,
    appSign:  /*input your AppSign*/,
    userID: currentUser.id,
    userName: currentUser.name,
    notifyWhenAppRunningInBackgroundOrQuit: false,
    plugins: [ZegoUIKitSignalingPlugin()],
    requireConfig: (ZegoCallInvitationData data) {
      final config = (data.invitees.length > 1)
          ? ZegoCallType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
          : ZegoCallType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

      /// support minimizing, show minimizing button
      config.topMenuBarConfig.isVisible = true;
      config.topMenuBarConfig.buttons.insert(0, ZegoMenuBarButtonName.minimizingButton);

      config.onOnlySelfInRoom = (context) {
        CallDurationWidget.stopTimer();
        Navigator.of(context).pop();
      };
      config.onHangUp = () {
        CallDurationWidget.stopTimer();
      };

      config.audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
        foregroundBuilder: (context, size, user, extraInfo) {
          final screenSize = MediaQuery.of(context).size;
          final isSmallView = size.height < screenSize.height / 2;
          if (isSmallView) {
            return Container();
          } else {
            return const CallDurationWidget();
          }
        },
      );

      return config;
    },
    events: ZegoUIKitPrebuiltCallInvitationEvents(
      onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
        // callee accepted the call, then start timer
        CallDurationWidget.startTimer();
      },
      onIncomingCallAcceptButtonPressed: () {
        // accept the call
        CallDurationWidget.startTimer();
      },
    ),
  );
}

/// on user logout
void onUserLogout() {
  /// 5/5. de-initialization ZegoUIKitPrebuiltCallInvitationService when account is logged out
  ZegoUIKitPrebuiltCallInvitationService().uninit();
  CallDurationWidget.stopTimer();
}

class CallDurationWidget extends StatelessWidget {
  const CallDurationWidget({Key? key}) : super(key: key);

  static DateTime callStartTime = DateTime.now();
  static ValueNotifier<DateTime> timeListenable = ValueNotifier<DateTime>(DateTime.now());
  static Timer? timer;

  
  static void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  static void startTimer() {
    timer?.cancel();
    callStartTime = DateTime.now();
    timeListenable.value = callStartTime;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeListenable.value = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallDurationWidget.timeListenable,
      builder: (context, DateTime currentTime, _) {
        final duration = currentTime.difference(CallDurationWidget.callStartTime);
        final durationText = duration.toText();
        debugPrint(durationText);
        return Stack(
          children: [
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  durationText,
                  style: const TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

extension DurationToText on Duration {
  String toText() {
    var microseconds = inMicroseconds;
    var hours = (microseconds ~/ Duration.microsecondsPerHour).abs();
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);
    if (microseconds < 0) microseconds = -microseconds;
    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);
    var minutesPadding = minutes < 10 ? "0" : "";
    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);
    var secondsPadding = seconds < 10 ? "0" : "";
    return '$hours:$minutesPadding$minutes:$secondsPadding$seconds';
  }
}
