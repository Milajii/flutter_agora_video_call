import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_agora_video_call/pages/video_channel_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType? _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Call"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.network("https://tinyurl.com/2p889y4k"),
            const SizedBox(height: 20),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                hintText: "Broadcaster channel: flutterapp",
                errorText:
                    _validateError ? "El nombre del canal es requerido," : null,
                border: const UnderlineInputBorder(
                    borderSide: BorderSide(width: 1)),
              ),
            ),
            RadioListTile(
              title: const Text("Creador"),
              value: ClientRoleType.clientRoleBroadcaster,
              groupValue: _role,
              onChanged: (ClientRoleType? value) {
                setState(() {
                  _role = value;
                });
              },
            ),
            RadioListTile(
              title: const Text("Espectador"),
              value: ClientRoleType.clientRoleAudience,
              groupValue: _role,
              onChanged: (ClientRoleType? value) {
                setState(() {
                  _role = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () => _onJoin(),
              child: const Text("Ingresar"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _onJoin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });

    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await _navigate();
    }
  }

  Future<void> _handleCameraAndMic(Permission value) async {
    final status = await value.request();
    log(status.toString());
  }

  Future<void> _navigate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoChannelPage(
          channelName: _channelController.text.trim(),
          role: _role,
        ),
      ),
    );
  }
}
