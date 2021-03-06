import 'package:hmssdk_flutter/meeting/meeting.dart';
import 'package:hmssdk_flutter/model/hms_config.dart';
import 'package:hmssdk_flutter/model/hms_peer.dart';
import 'package:hmssdk_flutter/model/hms_preview_listener.dart';
import 'package:hmssdk_flutter/model/hms_role.dart';
import 'package:hmssdk_flutter/model/hms_update_listener.dart';

class HMSSDKInteractor {
  late HMSConfig config;
  late HMSMeeting _meeting;

  HMSSDKInteractor() {
    _meeting = HMSMeeting();
  }

  Future<void> joinMeeting({required HMSConfig config}) async {
    this.config = config;
    await _meeting.joinMeeting(config: this.config);
  }

  Future<void> leaveMeeting() async {
    return await _meeting.leaveMeeting();
  }

  Future<void> switchAudio({bool isOn = false}) async {
    return await _meeting.switchAudio(isOn: isOn);
  }

  Future<void> switchVideo({bool isOn = false}) async {
    return await _meeting.switchVideo(isOn: isOn);
  }

  Future<void> switchCamera() async {
    return await _meeting.switchCamera();
  }

  Future<void> sendMessage(String message) async {
    return await _meeting.sendMessage(message);
  }

  Future<void> previewVideo({required HMSConfig config}) async {
    this.config = config;
    return _meeting.previewVideo(config: config);
  }

  void addMeetingListener(HMSUpdateListener listener) {
    _meeting.addMeetingListener(listener);
  }

  void removeMeetingListener(HMSUpdateListener listener) {
    _meeting.removeMeetingListener(listener);
  }

  void addPreviewListener(HMSPreviewListener listener) {
    _meeting.addPreviewListener(listener);
  }

  void removePreviewListener(HMSPreviewListener listener) {
    _meeting.removePreviewListener(listener);
  }

  void acceptRoleChangeRequest() {
    _meeting.acceptRoleChangerequest();
  }

  void stopCapturing() {
    _meeting.stopCapturing();
  }

  void startCapturing() {
    _meeting.startCapturing();
  }

  void changeRole(
      {required String peerId,
        required String roleName,
        bool forceChange = false}) {
    _meeting.changeRole(
        peerId: peerId, roleName: roleName, forceChange: forceChange);
  }

  Future<List<HMSRole>> getRoles() async {
    return _meeting.getRoles();
  }

  Future<bool> isAudioMute(HMSPeer? peer) async {
    bool isMute = await _meeting.isAudioMute(peer);
    return isMute;
  }

  Future<bool> isVideoMute(HMSPeer? peer) async {
    bool isMute = await _meeting.isVideoMute(peer);
    return isMute;
  }
}