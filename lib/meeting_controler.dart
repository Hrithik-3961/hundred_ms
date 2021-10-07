import 'package:hmssdk_flutter/model/hms_config.dart';
import 'package:hmssdk_flutter/model/hms_peer.dart';
import 'package:hmssdk_flutter/model/hms_preview_listener.dart';
import 'package:hmssdk_flutter/model/hms_role.dart';
import 'package:hmssdk_flutter/model/hms_update_listener.dart';
import 'package:hundred_ms/constants.dart';
import 'package:hundred_ms/room_service.dart';
import 'package:uuid/uuid.dart';

import 'hms_sdk_interactor.dart';
import 'meeting_flow.dart';

class MeetingController {
  final String roomUrl;
  final String user;
  final MeetingFlow flow;
  final HMSSDKInteractor? _hmsSdkInteractor;

  MeetingController(
      {required this.roomUrl, required this.user, required this.flow})
      : _hmsSdkInteractor = HMSSDKInteractor();

  Future<bool> joinMeeting() async {
    //List<String?>? token = await RoomService().getToken(user: user, room: roomUrl);
    //if(token==null)return false;
    HMSConfig config = HMSConfig(
        userId: const Uuid().v1(),
        roomId: roomUrl,
        authToken: Constant.hostToken,
        //endPoint: Constant.getTokenURL,
        userName: user);

    await _hmsSdkInteractor?.joinMeeting(config: config);
    return true;
  }

  void leaveMeeting() {
    _hmsSdkInteractor?.leaveMeeting();
  }

  Future<void> switchAudio({bool isOn = false}) async {
    return await _hmsSdkInteractor?.switchAudio(isOn: isOn);
  }

  Future<void> switchVideo({bool isOn = false}) async {
    return await _hmsSdkInteractor?.switchVideo(isOn: isOn);
  }

  Future<void> switchCamera() async {
    return await _hmsSdkInteractor?.switchCamera();
  }

  Future<void> sendMessage(String message) async {
    return await _hmsSdkInteractor?.sendMessage(message);
  }

  void addMeetingListener(HMSUpdateListener listener) {
    _hmsSdkInteractor?.addMeetingListener(listener);
  }

  void removeMeetingListener(HMSUpdateListener listener) {
    _hmsSdkInteractor?.removeMeetingListener(listener);
  }

  void addPreviewListener(HMSPreviewListener listener) {
    _hmsSdkInteractor?.addPreviewListener(listener);
  }

  void removePreviewListener(HMSPreviewListener listener) {
    _hmsSdkInteractor?.removePreviewListener(listener);
  }

  void acceptRoleChangeRequest() {
    _hmsSdkInteractor?.acceptRoleChangeRequest();
  }

  void stopCapturing() {
    _hmsSdkInteractor?.stopCapturing();
  }

  void startCapturing() {
    _hmsSdkInteractor?.startCapturing();
  }

  void changeRole(
      {required String peerId,
        required String roleName,
        bool forceChange = false}) {
    _hmsSdkInteractor?.changeRole(
        peerId: peerId, roleName: roleName, forceChange: forceChange);
  }

  Future<List<HMSRole>> getRoles() async {
    return _hmsSdkInteractor!.getRoles();
  }

  Future<bool> isAudioMute(HMSPeer? peer) async {
    bool isMute = await _hmsSdkInteractor!.isAudioMute(peer);
    return isMute;
  }

  Future<bool> isVideoMute(HMSPeer? peer) async {
    bool isMute = await _hmsSdkInteractor!.isVideoMute(peer);
    return isMute;
  }

}