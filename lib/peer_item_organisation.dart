import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/model/hms_track.dart';
import 'package:hmssdk_flutter/ui/meeting/video_view.dart';

class PeerItemOrganism extends StatefulWidget {
  final HMSTrack track;
  final bool isVideoMuted;

  const PeerItemOrganism(
      {Key? key, required this.track, this.isVideoMuted = true})
      : super(key: key);

  @override
  _PeerItemOrganismState createState() => _PeerItemOrganismState();
}

class _PeerItemOrganismState extends State<PeerItemOrganism> {
  GlobalKey key = GlobalKey();

  String name = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("isVideoMuted ${widget.isVideoMuted} ${widget.track.source} ${widget.track.peer?.name}");

    return Container(
      key: key,
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.all(2),
      height: 200.0,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Column(
        children: [
          Expanded(child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.isVideoMuted) {
                List<String> parts = widget.track.peer?.name.split(" ") ?? [];
                if (parts.length == 1) {
                  parts[0] += " ";
                  name = parts[0][0] + parts[0][1];
                } else if (parts.length >= 2) {
                  name = parts[0][0];
                  if (parts[1] == "" || parts[1] == " ") {
                    name += parts[0][1];
                  } else {
                    name += parts[1][0];
                  }
                }
                return Center(child: CircleAvatar(child: Text(name)));
              }

              return VideoView(
                track: widget.track,
              );
            },
          )),
        ],
      ),
    );
  }
}
