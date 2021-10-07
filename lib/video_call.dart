import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hmssdk_flutter/enum/hms_track_update.dart';
import 'package:hmssdk_flutter/model/hms_track.dart';
import 'package:hundred_ms/meeting_controler.dart';
import 'package:hundred_ms/meeting_flow.dart';
import 'package:hundred_ms/meeting_store.dart';
import 'package:hundred_ms/peer_item_organisation.dart';

class VideoCall extends StatefulWidget {
  final String userId;
  final String roomId;
  final MeetingFlow flow;

  const VideoCall(
      {Key? key,
      required this.userId,
      required this.roomId,
      required this.flow})
      : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  late MeetingStore _meetingStore;

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    _meetingStore = MeetingStore();
    MeetingController meetingController = MeetingController(
        roomUrl: widget.roomId, user: widget.userId, flow: widget.flow);
    _meetingStore.meetingController = meetingController;

    super.initState();
    joinCall();
  }

  Future<dynamic> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Leave the Meeting?'),
              actions: [
                TextButton(
                    onPressed: () => {
                          _meetingStore.meetingController.leaveMeeting(),
                          Navigator.pop(context, true),
                        },
                    child: const Text('Yes',
                        style: TextStyle(height: 1, fontSize: 24))),
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel',
                        style: TextStyle(
                            height: 1,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
              ],
            ));
  }

  void joinCall() async {
    bool ans = await _meetingStore.joinMeeting();
    if (!ans) {
      debugPrint("Unable to Join !");
      Navigator.of(context).pop();
    } else {
      debugPrint("Hoorah !!");
    }
    _meetingStore.startListen();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        bool ans = await _onBackPressed();
        return ans;
      },
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: double.infinity,
            child: Observer(
              builder: (_) {
                if (_meetingStore.tracks.isEmpty) {
                  return const Center(
                      child: Text('Waiting for other to join!'));
                }
                List<HMSTrack> filteredList = _meetingStore.tracks;

                switch (filteredList.length) {
                  case 1:
                    return Column(
                      children: [videoView(filteredList[0])],
                    );

                  case 2:
                    return Stack(
                      children: [
                        Column(
                          children: [videoView(filteredList[1])],
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                              margin: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.1,
                                  right:
                                      MediaQuery.of(context).size.width * 0.02),
                              width: 112.5,
                              height: 200,
                              child: videoView(filteredList[0])),
                        )
                      ],
                    );
                  default:
                    return const Center(
                        child: Text('More than 2 persons not allowed!'));
                }
              },
            ),
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Observer(builder: (context) {
                return IconButton(
                    tooltip: 'Video',
                    iconSize: 32,
                    onPressed: () {
                      _meetingStore.toggleVideo();
                    },
                    icon: Icon(_meetingStore.isVideoOn
                        ? Icons.videocam
                        : Icons.videocam_off));
              }),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Observer(builder: (context) {
                return IconButton(
                    tooltip: 'Audio',
                    iconSize: 32,
                    onPressed: () {
                      _meetingStore.toggleAudio();
                    },
                    icon: Icon(
                        _meetingStore.isMicOn ? Icons.mic : Icons.mic_off));
              }),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                  tooltip: 'Leave Or End',
                  iconSize: 32,
                  onPressed: () async {
                    _meetingStore.leaveMeeting();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.call_end)),
            ),
          ],
        ),
      ),
    );
  }

  Widget videoView(HMSTrack track) {
    return Expanded(
      child: PeerItemOrganism(
          track: track,
          isVideoMuted: track.peer!.isLocal
              ? !_meetingStore.isVideoOn
              : (_meetingStore.trackStatus[track.trackId]) ==
                  HMSTrackUpdate.trackMuted),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.startCapturing();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.stopCapturing();
      }
    } else if (state == AppLifecycleState.inactive) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.stopCapturing();
      }
    }
  }
}
