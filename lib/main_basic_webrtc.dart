import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();
  final TextEditingController _controller = TextEditingController();
  String screenlog = 'Application started';
  String templog = '';

  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;
    return stream;
  }

  _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream!);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    templog =
        '-----------------------------------------offer start------------------------------------';
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    templog = json.encode(session);
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    templog =
        '-----------------------------------------offer end------------------------------------';
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    print(
        '-----------------------------------------offer start------------------------------------');
    print(json.encode(session));
    print(
        '-----------------------------------------offer end------------------------------------');
    _offer = true;

    _peerConnection!.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    templog =
        '-----------------------------------------answer start------------------------------------';
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    templog = json.encode(session);
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    templog =
        '-----------------------------------------answer end------------------------------------';
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    print(
        '-----------------------------------------answer start------------------------------------');
    print(json.encode(session));
    print(
        '-----------------------------------------end------------------------------------');
    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);

    String sdp = write(session, null);

    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    templog = '$description.toMap()';
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);
    templog = session['candidate'];
    setState(() {
      screenlog = '$screenlog\n$templog';
      _controller.text = screenlog;
    });
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  @override
  void initState() {
    initRenderer();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    // _getUserMedia();
    super.initState();
    _controller.text = '';
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(children: [
          Flexible(
            child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
          ),
        ]),
      );
  String name = '';
  String password = '';
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              videoRenderers(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextField(
                            controller: sdpController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            maxLength: TextField.noMaxLength,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _createOffer,
                    child: const Text("Offer"),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  ElevatedButton(
                    onPressed: _createAnswer,
                    child: const Text("Answer"),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  ElevatedButton(
                    onPressed: _setRemoteDescription,
                    child: const Text("Set Remote Description"),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  ElevatedButton(
                    onPressed: _addCandidate,
                    child: const Text("Set Candidate"),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(onChanged: (value) {
                    name = value;
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(onChanged: (value) {
                    password = value;
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  TextButton(
                    onPressed: () async {
                      print(name);
                      print(password);
                      try {
                        final newUser =
                            await _auth.createUserWithEmailAndPassword(
                                email: name, password: password);
                        if (newUser != null) {
                          print(
                              '==================firebase completed==========================');
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text('TextButton'),
                  )
                ],
              ),
              Card(
                  color: Colors.grey,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      maxLines: null,
                      minLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        fillColor: Colors.black,
                        filled: true, // dont forget this line
                      ),
                      controller: _controller,
                    ),
                  ))
            ],
          ),
        ));
  }
}
