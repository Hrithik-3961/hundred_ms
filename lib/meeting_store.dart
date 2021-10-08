import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hmssdk_flutter/enum/hms_peer_update.dart';
import 'package:hmssdk_flutter/enum/hms_room_update.dart';
import 'package:hmssdk_flutter/enum/hms_track_kind.dart';
import 'package:hmssdk_flutter/enum/hms_track_source.dart';
import 'package:hmssdk_flutter/enum/hms_track_update.dart';
import 'package:hmssdk_flutter/model/hms_error.dart';
import 'package:hmssdk_flutter/model/hms_message.dart';
import 'package:hmssdk_flutter/model/hms_peer.dart';
import 'package:hmssdk_flutter/model/hms_role.dart';
import 'package:hmssdk_flutter/model/hms_role_change_request.dart';
import 'package:hmssdk_flutter/model/hms_room.dart';
import 'package:hmssdk_flutter/model/hms_speaker.dart';
import 'package:hmssdk_flutter/model/hms_track.dart';
import 'package:hmssdk_flutter/model/hms_update_listener.dart';
import 'package:hundred_ms/meeting_controler.dart';
import 'package:mobx/mobx.dart';

part 'meeting_store.g.dart';

class MeetingStore = MeetingStoreBase with _$MeetingStore;

abstract class MeetingStoreBase with Store implements HMSUpdateListener {
  @observable
  bool isSpeakerOn = true;

  @observable
  HMSError? error;

  @observable
  HMSRoleChangeRequest? roleChangeRequest;

  @observable
  bool isMeetingStarted = false;
  @observable
  bool isVideoOn = true;
  @observable
  bool isMicOn = true;
  @observable
  bool reconnecting = false;
  @observable
  bool reconnected = false;

  late MeetingController meetingController;

  @observable
  List<HMSPeer> peers = ObservableList.of([]);

  @observable
  HMSPeer? localPeer;

  @observable
  HMSTrack? screenTrack;

  @observable
  List<HMSTrack> tracks = ObservableList.of([]);

  @observable
  List<HMSMessage> messages = ObservableList.of([]);

  @observable
  ObservableMap<String, HMSTrackUpdate> trackStatus = ObservableMap.of({});

  @observable
  ObservableMap<String, HMSTrackUpdate> audioTrackStatus = ObservableMap.of({});

  @action
  void startListen() {
    meetingController.addMeetingListener(this);
  }

  @action
  void toggleSpeaker() {
    debugPrint("toggleSpeaker");
    isSpeakerOn = !isSpeakerOn;
  }

  @action
  Future<void> toggleVideo() async {
    debugPrint("toggleVideo $isVideoOn");
    await meetingController.switchVideo(isOn: isVideoOn);
    isVideoOn = !isVideoOn;
  }

  @action
  Future<void> toggleCamera() async {
    await meetingController.switchCamera();
  }

  @action
  Future<void> toggleAudio() async {
    await meetingController.switchAudio(isOn: isMicOn);
    isMicOn = !isMicOn;
  }

  @action
  void removePeer(HMSPeer peer) {
    peers.remove(peer);
    removeTrackWithPeerId(peer.peerId);
  }

  @action
  void addPeer(HMSPeer peer) {
    if (!peers.contains(peer)) peers.add(peer);
  }

  @action
  void removeTrackWithTrackId(String trackId) {
    tracks.removeWhere((eachTrack) => eachTrack.trackId == trackId);
  }

  @action
  void removeTrackWithPeerId(String peerId) {
    tracks.removeWhere((eachTrack) => eachTrack.peer?.peerId == peerId);
  }

  @action
  void addTrack(HMSTrack track) {
    if (tracks.contains(track)) removeTrackWithTrackId(track.trackId);

    if (track.source == HMSTrackSource.kHMSTrackSourceScreen) {
      tracks.insert(0, track);
    } else {
      tracks.insert(tracks.length, track);
    }
    debugPrint("addTrack");
  }

  @action
  void onRoleUpdated(int index, HMSPeer peer) {
    peers[index] = peer;
  }

  @action
  Future<bool> joinMeeting() async {
    bool ans = await meetingController.joinMeeting();
    if (!ans) return false;
    isMeetingStarted = true;
    return true;
  }

  @action
  Future<void> sendMessage(String message) async {
    await meetingController.sendMessage(message);
  }

  @action
  void updateError(HMSError error) {
    this.error = error;
  }

  @action
  void updateRoleChangeRequest(HMSRoleChangeRequest roleChangeRequest) {
    this.roleChangeRequest = roleChangeRequest;
  }

  @action
  void addMessage(HMSMessage message) {
    messages.add(message);
  }

  @action
  void updatePeerAt(peer) {
    int index = peers.indexOf(peer);
    peers.removeAt(index);
    peers.insert(index, peer);
  }

  @override
  void onJoin({required HMSRoom room}) {
    if (Platform.isAndroid) {
      debugPrint("members ${room.peers!.length}");
      for (HMSPeer each in room.peers!) {
        if (each.isLocal) {
          localPeer = each;
          addPeer(localPeer!);
          debugPrint('on join ${localPeer!.peerId}');
          break;
        }
      }
    } else {
      for (HMSPeer each in room.peers!) {
        addPeer(each);
        if (each.isLocal) {
          localPeer = each;
          debugPrint('on join ${localPeer!.name}  ${localPeer!.peerId}');
          if (each.videoTrack != null) {
            tracks.insert(0, each.videoTrack!);
          }
        } else {
          if (each.videoTrack != null) {
            tracks.insert(0, each.videoTrack!);
          }
        }
      }
    }
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {
    debugPrint('on room update');
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    peerOperation(peer, update);
  }

  @override
  void onTrackUpdate(
      {required HMSTrack track,
        required HMSTrackUpdate trackUpdate,
        required HMSPeer peer}) {
    debugPrint("onTrackUpdateFlutter $track ${peer.isLocal}");
    if (track.kind == HMSTrackKind.kHMSTrackKindAudio) {
      audioTrackStatus[track.trackId] = trackUpdate;
      if (peer.isLocal && trackUpdate == HMSTrackUpdate.trackMuted) {
        isMicOn = false;
      }
      return;
    }
    trackStatus[track.trackId] = HMSTrackUpdate.trackMuted;

    debugPrint("onTrackUpdate ${trackStatus[track.trackId]}");

    if (peer.isLocal) {
      localPeer = peer;

      if (Platform.isAndroid) {
        int screenShareIndex = tracks.indexWhere((element) {
          return element.source == HMSTrackSource.kHMSTrackSourceScreen;
        });
        debugPrint("ScreenShare $screenShareIndex");
        if (screenShareIndex == -1) {
          tracks.insert(0, track);
        } else {
          tracks.insert(1, track);
        }
      }
    } else {
      peerOperationWithTrack(peer, trackUpdate, track);
    }
  }

  @override
  void onError({required HMSError error}) {
    updateError(error);
  }

  @override
  void onMessage({required HMSMessage message}) {
    addMessage(message);
  }

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {
    debugPrint("onRoleChangeRequest Flutter");
    updateRoleChangeRequest(roleChangeRequest);
  }

  HMSTrack? previousHighestVideoTrack;
  int? previousHighestIndex;

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {
    /*if (updateSpeakers.length == 0) return;
    HMSSpeaker highestAudioSpeaker = updateSpeakers[0];
    int newHighestIndex = tracks.indexWhere(
            (element) => element.peer?.peerId == highestAudioSpeaker.peerId);
    if (newHighestIndex == -1) return;

    if (previousHighestVideoTrack != null) {
      HMSTrack newPreviousTrack =
      HMSTrack.copyWith(false, track: previousHighestVideoTrack!);

      int newPrevHighestIndex = tracks.indexWhere((element) {
        print(element.peer?.peerId == previousHighestVideoTrack?.peer?.peerId);

        return element.peer?.peerId == previousHighestVideoTrack?.peer?.peerId;
      });
      if (newPrevHighestIndex != -1) {
        tracks.removeAt(newPrevHighestIndex);

        tracks.insert(newPrevHighestIndex, newPreviousTrack);
      }
    }
    HMSTrack highestAudioSpeakerVideoTrack = tracks[newHighestIndex];
    HMSTrack newHighestTrack =
    HMSTrack.copyWith(true, track: highestAudioSpeakerVideoTrack);
    tracks.removeAt(newHighestIndex);
    tracks.insert(newHighestIndex, newHighestTrack);
    previousHighestVideoTrack = newHighestTrack;*/
  }

  @override
  void onReconnecting() {
    reconnecting = true;
  }

  @override
  void onReconnected() {
    reconnecting = false;
    reconnected = true;
  }

  int trackChange = -1;

  void changeTracks() {
    debugPrint("flutteronChangeTracks $trackChange");
    if (trackChange == 1) {
      toggleVideo();
    } else if (trackChange == 0) {
      toggleAudio();
    }
  }

  void changeRole(
      {required String peerId,
        required String roleName,
        bool forceChange = false}) {
    meetingController.changeRole(
        roleName: roleName, peerId: peerId, forceChange: forceChange);
  }

  Future<List<HMSRole>> getRoles() async {
    return meetingController.getRoles();
  }

  @action
  void peerOperation(HMSPeer peer, HMSPeerUpdate update) {
    switch (update) {
      case HMSPeerUpdate.peerJoined:
        debugPrint('peer joined');
        addPeer(peer);
        break;
      case HMSPeerUpdate.peerLeft:
        debugPrint('peer left');
        removePeer(peer);

        break;
      case HMSPeerUpdate.peerKnocked:
      // removePeer(peer);
        break;
      case HMSPeerUpdate.audioToggled:
        debugPrint('Peer audio toggled');
        break;
      case HMSPeerUpdate.videoToggled:
        debugPrint('Peer video toggled');
        break;
      case HMSPeerUpdate.roleUpdated:
        debugPrint('${peers.indexOf(peer)}');
        updatePeerAt(peer);
        break;
      case HMSPeerUpdate.defaultUpdate:
        debugPrint("Some default update or untouched case");
        break;
      default:
        debugPrint("Some default update or untouched case");
    }
  }

  @action
  void peerOperationWithTrack(
      HMSPeer peer, HMSTrackUpdate update, HMSTrack track) {
    debugPrint("onTrackUpdateFlutter $update ${peer.isLocal} update");
    switch (update) {
      case HMSTrackUpdate.trackAdded:
        addTrack(track);
        break;
      case HMSTrackUpdate.trackRemoved:
        removeTrackWithTrackId(track.trackId);
        break;
      case HMSTrackUpdate.trackMuted:
        break;
      case HMSTrackUpdate.trackUnMuted:
        break;
      case HMSTrackUpdate.trackDescriptionChanged:
        break;
      case HMSTrackUpdate.trackDegraded:
        break;
      case HMSTrackUpdate.trackRestored:
        break;
      case HMSTrackUpdate.defaultUpdate:
        break;
      default:
        debugPrint("Some default update or untouched case");
    }
  }

  void leaveMeeting() {
    meetingController.leaveMeeting();
  }
}