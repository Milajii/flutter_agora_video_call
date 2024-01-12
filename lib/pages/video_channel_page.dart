import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_agora_video_call/utils/settings.dart';

class VideoChannelPage extends StatefulWidget {
  const VideoChannelPage({super.key, this.channelName, this.role});

  final String? channelName;
  final ClientRoleType? role;

  @override
  State<VideoChannelPage> createState() => _VideoChannelPageState();
}

class _VideoChannelPageState extends State<VideoChannelPage> {
  final _users = [];
  final _infoStrings = [];
  late RtcEngine _engine;

  bool muted = false;
  bool viewPanel = false;

  @override
  void initState() {
    initalize();
    super.initState();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> initalize() async {
    if (Settings.appId.isEmpty) {
      setState(() {
        _infoStrings.add(
            "APP_ID is missing, please provide your APP_ID in settings.dart");
        _infoStrings.add("Agora Engine is not starting.");
      });
      return;
    }

    // Create an instance of the Agora engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: Settings.appId));
    await _engine.enableVideo();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.role!);
    // Add Agora Event Handlers
    _addAgoraEventHandlers();

    VideoEncoderConfiguration configuration = const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 1920, height: 1080),
    );

    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
      token: Settings.token,
      channelId: widget.channelName!,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.release();
  }

  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
        if (!mounted) return;
        setState(() {
          final info = "Error: $err Message: $msg";
          _infoStrings.add(info);
        });
      },
      onJoinChannelSuccess: (connection, elapsed) {
        if (!mounted) return;
        setState(() {
          final info =
              "Join Channel ${connection.channelId} uid: ${connection.localUid}";
          _infoStrings.add(info);
        });
      },
      onLeaveChannel: (connection, stats) {
        if (!mounted) return;
        setState(() {
          _infoStrings.add("Leave Channel");
          _users.clear();
        });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted) return;
        setState(() {
          final info = "User Joined $remoteUid";
          _infoStrings.add(info);
          _users.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted) return;
        setState(() {
          final info = "User Offline $remoteUid";
          _infoStrings.add(info);
          _users.remove(remoteUid);
        });
      },
      onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
        if (!mounted) return;
        setState(() {
          final info = "First Remote Video: $remoteUid $width x $height";
          _infoStrings.add(info);
        });
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dispose();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Video Call Channel"),
          actions: [
            IconButton(
              onPressed: () => setState(() => viewPanel = !viewPanel),
              icon: const Icon(Icons.info_outline_rounded),
            )
          ],
        ),
        body: Stack(
          children: [
            _viewRows(),
            _panel(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  // Video of each user
  Widget _viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      list.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }

    for (var uid in _users) {
      list.add(AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      ));
    }
    final views = list;

    return Column(
      children: List.generate(
        views.length,
        (index) => Expanded(child: views[index]),
      ),
    );
  }

  Widget _toolbar() {
    if (widget.role == ClientRoleType.clientRoleAudience) {
      return const SizedBox.shrink();
    } else {
      return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              shape: const CircleBorder(),
              elevation: 2.0,
              color: muted ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12),
              onPressed: () {
                setState(() {
                  muted = !muted;
                });
                _engine.muteLocalAudioStream(muted);
              },
              child: Icon(
                muted ? Icons.mic_off_rounded : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
              ),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              color: Colors.redAccent,
              padding: const EdgeInsets.all(15),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 35,
              ),
            ),
            MaterialButton(
              shape: const CircleBorder(),
              elevation: 2.0,
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              onPressed: () {
                _engine.switchCamera();
              },
              child: const Icon(
                Icons.cameraswitch_rounded,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: ListView.builder(
              reverse: true,
              itemCount: _infoStrings.length,
              itemBuilder: (context, index) {
                if (_infoStrings.isEmpty) {
                  return const Text("null");
                } else {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _infoStrings[index],
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
