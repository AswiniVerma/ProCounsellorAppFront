import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:my_app/services/video_call_service.dart';
import 'package:my_app/services/firebase_signaling_service.dart';

class VideoCallPage extends StatefulWidget {
  final String callId;
  final String id;
  final bool isCaller;

  VideoCallPage(
      {required this.callId, required this.id, required this.isCaller});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final FirebaseSignalingService _signalingService = FirebaseSignalingService();
  final VideoCallService _callService = VideoCallService();
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initWebRTC();
    _signalingService.listenForCallEnd(widget.callId, _handleCallEnd);
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    Map<String, dynamic> config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _callService.sendIceCandidate(widget.callId, candidate, widget.id);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    _localRenderer.srcObject = localStream;

    for (var track in localStream.getTracks()) {
      _peerConnection!.addTrack(track, localStream);
    }

    if (widget.isCaller) {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _callService.sendOffer(widget.callId, offer);
    } else {
      _signalingService.listenForOffer(widget.callId, (offer) async {
        if (offer.isNotEmpty) {
          await _peerConnection!
              .setRemoteDescription(RTCSessionDescription(offer, "offer"));
          RTCSessionDescription answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          _callService.sendAnswer(widget.callId, answer);
        }
      });
    }

    _signalingService.listenForAnswer(widget.callId, _peerConnection!,
        (answerString) async {
      RTCSessionDescription answer =
          RTCSessionDescription(answerString, "answer");
      if (_peerConnection != null) {
        await _peerConnection!.setRemoteDescription(answer);
      }
    });

    _signalingService.listenForIceCandidates(widget.callId, (candidate) async {
      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(RTCIceCandidate(
          candidate["candidate"],
          candidate["sdpMid"],
          candidate["sdpMLineIndex"],
        ));
      }
    });
  }

  void _handleCallEnd() {
    if (mounted) {
      _peerConnection?.close();
      Navigator.pop(context);
    }
  }

  void _endCall() {
    _peerConnection?.close();
    _callService.endCall(widget.callId);
  }

  @override
  void dispose() {
    _peerConnection?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer, mirror: true),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            child: ElevatedButton(
              onPressed: _endCall,
              child: Text("End Call", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
