import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hmssdk_flutter/enum/hms_track_source.dart';
import 'package:hmssdk_flutter/enum/hms_track_update.dart';
import 'package:hmssdk_flutter/model/hms_track.dart';
import 'package:hundred_ms/meeting_controler.dart';
import 'package:hundred_ms/meeting_flow.dart';
import 'package:hundred_ms/meeting_store.dart';
import 'package:hundred_ms/peer_item_organisation.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  late ScrollController _scrollController;

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    _scrollController = ScrollController();
    _meetingStore = MeetingStore();
    MeetingController meetingController = MeetingController(roomUrl: widget.roomId, user: widget.userId, flow: widget.flow);
    _meetingStore.meetingController = meetingController;

    super.initState();
    joinCall();
  }

  void joinCall() async {
    bool ans = await _meetingStore.joinMeeting();
    if (!ans) {
      print("Unable to Join !");
      Navigator.of(context).pop();
    }
    else
      print("Hoooorah !!");
    _meetingStore.startListen();
  }

  @override
  Widget build(BuildContext context) {

    var orientation = MediaQuery.of(context).orientation;
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2.5;
    final double itemWidth = size.width / 2;
    final aspectRatio = itemHeight / itemWidth;

    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          child: Observer(
            builder: (_) {
              if (_meetingStore.tracks.isEmpty) {
                return const Center(child: Text('Waiting for other to join!'));
              }
              List<HMSTrack> filteredList = _meetingStore.tracks;
              return StaggeredGridView.count(
                // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //     crossAxisCount: 2),
                crossAxisCount: 2,
                controller: _scrollController,
                //childAspectRatio: itemWidth / itemHeight,
                staggeredTiles: List.generate(
                  filteredList.length,
                  (int index) => StaggeredTile.count(
                      filteredList[index].source ==
                              HMSTrackSource.kHMSTrackSourceScreen
                          ? 2
                          : 1,
                      filteredList[index].source ==
                              HMSTrackSource.kHMSTrackSourceScreen
                          ? orientation == Orientation.portrait
                              ? aspectRatio * 2 + 0.1
                              : aspectRatio * 2 - 0.1
                          : orientation == Orientation.portrait
                              ? aspectRatio
                              : aspectRatio * 2 - 0.1),
                ),
                children: List.generate(filteredList.length, (index) {
                  return VisibilityDetector(
                    onVisibilityChanged: (VisibilityInfo info) {
                      var visiblePercentage = info.visibleFraction * 100;
                      print(
                          "$index  ${filteredList[index].peer!.name} lengthofFilteredList");
                      String trackId = filteredList[index].trackId;
                      print(filteredList[index].isMute);
                      if (visiblePercentage <= 40) {
                        _meetingStore.trackStatus[trackId] =
                            HMSTrackUpdate.trackMuted;
                      } else {
                        /*_meetingStore.trackStatus[trackId] =
                            filteredList[index].isMute
                                ? HMSTrackUpdate.trackMuted
                                : HMSTrackUpdate.trackUnMuted;*/
                        print(_meetingStore.trackStatus[trackId]);
                      }
                      debugPrint(
                          'Widget ${info.key} is $visiblePercentage% visible and index is ${index}');
                    },
                    key: Key(filteredList[index].trackId),
                    child: InkWell(
                      onLongPress: () {
                        if (!filteredList[index].peer!.isLocal &&
                            filteredList[index].source !=
                                HMSTrackSource.kHMSTrackSourceScreen) {

                        }
                      },
                      child: PeerItemOrganism(
                          track: filteredList[index],
                          isVideoMuted: filteredList[index].peer!.isLocal
                              ? !_meetingStore.isVideoOn
                              : (_meetingStore.trackStatus[
                                      filteredList[index].trackId]) ==
                                  HMSTrackUpdate.trackMuted),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
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
