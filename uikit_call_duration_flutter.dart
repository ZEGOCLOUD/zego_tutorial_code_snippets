class HomePageState extends State<HomePage> {
  DateTime callStartTime = DateTime.now();
  ValueNotifier<DateTime> timeListenable =
      ValueNotifier<DateTime>(DateTime.now());

  Timer? timer;

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  void startTImer() {
    timer?.cancel();
    callStartTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeListenable.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: ZegoUIKitPrebuiltCallWithInvitation(
            appID: ,
            appSign:,
            userID: currentUser.id,
            userName: currentUser.name,
            notifyWhenAppRunningInBackgroundOrQuit: true,
            isIOSSandboxEnvironment: false,
            androidNotificationConfig: ZegoAndroidNotificationConfig(
              channelID: "ZegoUIKit",
              channelName: "Call Notifications",
              sound: "zego_incoming",
            ),
            plugins: [ZegoUIKitSignalingPlugin()],
            requireConfig: (ZegoCallInvitationData data) {
              final config = ZegoCallType.videoCall == data.type
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
              config.onOnlySelfInRoom = (context) {
                stopTimer();
                Navigator.of(context).pop();
              };
              config.onHangUp = () {
                stopTimer();
              };

              // callDurationTimer.cancel();
              config.audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
                foregroundBuilder: (context, size, user, extraInfo) {
                  final screenSize = MediaQuery.of(context).size;
                  final isSmallView = size.height < screenSize.height / 2;
                  if (isSmallView) {
                    return Container();
                  } else {
                    return ValueListenableBuilder(
                        valueListenable: timeListenable,
                        builder: (context, DateTime currentTime, _) {
                          return Text(
                              '${currentTime.difference(callStartTime)}');
                        });
                  }
                },
              );

              return config;
            },
            events: ZegoUIKitPrebuiltCallInvitationEvents(
              onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
                // callee accepted the call, then start timer
                startTImer();
              },
              onIncomingCallAcceptButtonPressed: () {
                // accept the call
                startTImer();
              },
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Text('Home Page', textAlign: TextAlign.center),
                ),
                Positioned(
                  top: 20,
                  right: 10,
                  child: logoutButton(),
                ),
                Positioned(
                  top: 50,
                  left: 10,
                  child: Text('Your user ID: ${currentUser.id}'),
                ),
                userListView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
