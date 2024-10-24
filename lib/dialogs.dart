import 'package:clue_client/clue_client.dart';
import 'package:flutter/material.dart';
import 'package:zugclient/zug_client.dart';

class InfoDialog {
  final BuildContext ctx;
  final String msg;

  InfoDialog(this.ctx, this.msg);

  Future<void> raise() {
    return showDialog<void>(
        context: ctx,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              Text(msg),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK')),
            ],
          );
        });
  }
}

class SoundDialog extends StatefulWidget {
  final ClueClient client;
  final BuildContext ctx;

  const SoundDialog(this.client, this.ctx, {super.key});

  @override
  State<StatefulWidget> createState() => _SoundDialogState();
}

class _SoundDialogState extends State<SoundDialog> {

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        checkPref(widget.client,"Sounds",AudioType.sound.name,true,onFalse: () => setState(() {}), onTrue: () => setState(() {})),
        checkPref(widget.client,"Music",AudioType.music.name,true,
            onFalse: () {
              setState((){});
              widget.client.trackPlayer.stop();
            },
            onTrue: () {
              setState((){});
              widget.client.playMusic("clue_track_1");
            }),
        SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Return')),
      ],
    );
  }
}

Row checkPref(ClueClient client, String caption, String prefProp, bool defaultValue, {VoidCallback? onTrue, VoidCallback? onFalse}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("$caption:"),
      Checkbox(
          value: client.prefs?.getBool(prefProp) ?? defaultValue,
          onChanged: (b) {
            client.prefs?.setBool(prefProp, b ?? defaultValue);
            ZugClient.log.info("Setting $caption: $b");
            if ((b ?? false)) {
              if (onTrue != null) onTrue();
            } else {
              if (onFalse != null) {
                onFalse();
              }
            }
          }),
    ],
  );
}