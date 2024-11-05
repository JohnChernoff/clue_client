import 'package:clue_client/clue_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_client.dart';
import "package:universal_html/html.dart" as html;

class OptionsDialogWidget extends StatefulWidget {
  final ClueClient client;

  const OptionsDialogWidget(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _OptionsDialogWidgetState();

}

class _OptionsDialogWidgetState extends State<OptionsDialogWidget> {
  TimerMode? timerMode;
  MixStyle? mixStyle;
  bool? showControl;
  bool? simpleSquares;
  bool? fixedTime;

  Widget clueTxt(String txt) {
    return Text(txt,style: const TextStyle(color: Colors.black));
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(children: [
        DropdownButton<MixStyle>(
          style: const TextStyle(color: Colors.black), dropdownColor: Colors.grey,
          value: mixStyle ?? widget.client.mixStyle,
          items: List.generate(
              MixStyle.values.length,
                  (i) => DropdownMenuItem(
                value: MixStyle.values.elementAt(i),
                child: clueTxt(
                    "Color Mixture Style: ${MixStyle.values.elementAt(i).name}"),
              )),
          onChanged: (MixStyle? value) =>
            setState(() => widget.client.mixStyle = mixStyle = value!),
        ),
        Row(children: [
          clueTxt("Simple Squares: "),
          Checkbox(
              value: simpleSquares ?? widget.client.simpleSquares,
              onChanged: (b) => setState(() => widget.client.simpleSquares = simpleSquares =
              !widget.client.simpleSquares))
        ]),
        Row(children: [
          clueTxt("Show Control Numbers: "),
          Checkbox(
              value: showControl ?? widget.client.showControl,
              onChanged: (b) => setState(() => widget.client.showControl = showControl = b ?? false))
        ]),
        //checkPref(widget.client,widget.client.isFixedTime() ? "Timer Mode: 3 minutes" : "Timer Mode: 5 boards", "fixed_time",true,onFalse: () => setState(() {}), onTrue: () => setState(() {})),
      DropdownButton<TimerMode>(
        style: const TextStyle(color: Colors.black), dropdownColor: Colors.grey,
        value: timerMode ?? widget.client.timerMode,
        items: List.generate(
            TimerMode.values.length,
                (i) => DropdownMenuItem(
              value: TimerMode.values.elementAt(i),
              child: clueTxt(
                  "Timer Mode: ${TimerMode.values.elementAt(i).toString()}"),
            )),
        onChanged: (TimerMode? value) =>
            setState(() => widget.client.timerMode = timerMode = value!),
      ),
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
        TextButton(onPressed: () => Navigator.pop(context), child: clueTxt("Return")),
      ],
    );
  }
}

class InfoDialog {
  final BuildContext ctx;
  final String msg;

  const InfoDialog(this.ctx, this.msg);

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

class IntroDialog {
  String tutorialUrl, discordUrl;
  final BuildContext ctx;

  IntroDialog(this.ctx,this.tutorialUrl, this.discordUrl);

  Future<bool?> raise() {
    return showDialog<bool?>(
        context: ctx,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text("Welcome to Cluechess!"),
            children: [
              SimpleDialogOption(
                  onPressed: () {
                    if (kIsWeb) {
                      html.window.open(tutorialUrl, 'new tab');
                    } else {
                      ZugUtils.launch(tutorialUrl, isNewTab: true);
                    }
                  },
                  child: const Text('Learn ClueChess')),
              SimpleDialogOption(
                  onPressed: () {
                    if (kIsWeb) {
                      html.window.open(discordUrl, 'new tab');
                    } else {
                      ZugUtils.launch(discordUrl, isNewTab: true);
                    }
                  },
                  child: const Text('Visit Discord')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context,false);
                  },
                  child: const Text('Start without Music')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context,true);
                  },
                  child: const Text('Start with Music')),
            ],
          );
        });
  }
}

Row checkPref(ClueClient client, String caption, String prefProp, bool defaultValue, {VoidCallback? onTrue, VoidCallback? onFalse}) {
  return Row( //mainAxisAlignment: MainAxisAlignment.center,
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

class TopDialog {
  BuildContext ctx;
  List<dynamic> data;
  TopDialog(this.ctx, this.data);
  
  Future<bool?> raise() {
    return showDialog<bool?>(
        context: ctx,
        builder: (BuildContext context) {
          return SimpleDialog(children: [DataTable(columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Time")),
                DataColumn(label: Text("Boards")),
              ], rows: List.generate(data.length, (index) =>
                  DataRow(cells: [
                    DataCell(getCell(data[index]?["playerName"] ?? "?",Colors.white,Colors.black)),
                    DataCell(getCell(data[index]?["unfixedTime"]?.toString() ?? "?",Colors.white,Colors.black)),
                    DataCell(getCell(data[index]?["solved"]?.toString() ?? "?",Colors.white,Colors.black)),
                  ])),
          )]);
        });
  }

  Widget getCell(String txt, Color bgCol, Color txtCol) {
    return Container(color: bgCol, child: Text(txt,style: TextStyle(color: txtCol)));
  }
}