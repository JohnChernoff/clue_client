import 'dart:math';
import 'package:clue_client/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_fields.dart';
import 'board_widget.dart';
import 'clue_client.dart';
import 'clue_game.dart';

class MainPage extends StatefulWidget {
  final ClueClient client;
  final landWidth = 800.0;
  const MainPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();

}

class _MainPageState extends State<MainPage> {
  bool controlsRow(double w) => w > widget.landWidth;

  @override
  void initState() {
    widget.client.areaCmd(ClientMsg.setDeaf,data:{fieldDeafened:false});
    super.initState();
  }

  Widget clueTxt(String txt) {
    return Text(txt,style: const TextStyle(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.client.currentArea as ClueGame;
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
      double boardSize = min(constraints.maxHeight - 32, constraints.maxWidth);
      bool landscape = constraints.maxHeight - 32 < constraints.maxWidth;
      return Container(
          decoration: BoxDecoration(
            image: DecorationImage(fit: BoxFit.fill, image: ZugUtils.getAssetImage("images/clue_bkg.png")),
          ),
          child: Center(child: SizedBox(
            width: landscape ? null : boardSize,
            height: landscape ? boardSize : null,
            child: Column(
              children: [
                getControls(game, boardSize, landscape ? Axis.horizontal : Axis.vertical),
                Expanded(child: AnimatedSwitcher(
                    duration: Duration(seconds: game.result == ClueResult.playing || game.isTimed ? 1 : 5),
                    child: ClueBoardWidget(widget.client, game, boardSize,
                      key: game.result == ClueResult.playing ? const ValueKey("1") : const ValueKey("2"))),
                ),
              ],
            ),
          )
        )
      );
    });
  }

  Widget getControls(ClueGame game, double width, Axis axis) {
    Padding pad = Padding(padding: axis == Axis.horizontal ? const EdgeInsets.all(16.0) : const EdgeInsets.all(4.0));
    return Container(
        width: width,
        color: Colors.black,
        child: FittedBox(fit: BoxFit.scaleDown, child: Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: axis,
            children: [
              IconButton(onPressed: () => widget.client.send(ClueMsg.top, data: widget.client.timerMode.toJSON()),
                  icon: const Icon(Icons.scoreboard),
              ),
              IconButton(onPressed: () => showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => OptionsDialogWidget(widget.client)),
                icon: const Icon(Icons.settings)
              ),
              pad,
              clueTxt("Guesses Remaining: ${game.guessesLeft}"),
              pad,
              if (game.toGo > 0) clueTxt("To Go: ${game.toGo}"), //pad,
              game.isTimed
                  ? TextButton(
                  onPressed: () => widget.client.areaCmd(ClueMsg.abortTimer),
                  child: const Text("Abort Timer"))
                  : TextButton(
                  onPressed: () => widget.client.startTimer(widget.client.timerMode),
                  child: const Text("Start Timer")),
              if (game.countUp != null) ClueTimerWidget(game.countUp!, true)
              else if (game.countDown != null) ClueTimerWidget(game.countDown!, false),
            ])));
  }

}

class ClueTimerWidget extends StatefulWidget {
  final int startSeconds;
  final bool up;

  const ClueTimerWidget(this.startSeconds,this.up,{super.key});

  @override
  State<StatefulWidget> createState() => _ClueTimerWidgetState();

}

class _ClueTimerWidgetState extends State<ClueTimerWidget> {
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    seconds = widget.startSeconds;
    nextTick();
  }

  void nextTick() {
    if (mounted) {
      if (widget.up) {
        setState(() => seconds++);
      } else if (seconds > 0) {
        setState(() => seconds--);
      }
      Future.delayed(const Duration(seconds: 1)).then((v) => nextTick());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text("Seconds: $seconds",style: const TextStyle(color: Colors.amber));
  }

}


