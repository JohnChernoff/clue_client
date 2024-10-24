import 'dart:math';
import 'package:clue_client/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/dialogs.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_fields.dart';
import 'clue_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'clue_game.dart';

class MainPage extends StatefulWidget {
  final ClueClient client;
  final landWidth = 800.0;
  const MainPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();

}

class _MainPageState extends State<MainPage> {
  bool showControl = false;
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
            image: DecorationImage(fit: BoxFit.fill, image: ZugUtils.getAssetImage("images/goth_back.jpg")),
          ),
          child: Center(child: SizedBox(
            width: landscape ? null : boardSize,
            height: landscape ? boardSize : null,
            child: Column(
              children: [
                getControls(game, boardSize, landscape ? Axis.horizontal : Axis.vertical),
                Expanded(child: game.result == ClueResult.playing || widget.client.playingClip
                  ? getBoard(game,min(800,boardSize))
                  : InkWell(child: getBoard(game,min(800,boardSize)),
                    onTap: () => widget.client.areaCmd(ClueMsg.newBoard))),
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
              DropdownButton<MixStyle>(
                style: const TextStyle(color: Colors.black), dropdownColor: Colors.grey,
                value: widget.client.mixStyle,
                items: List.generate(
                    MixStyle.values.length,
                    (i) => DropdownMenuItem(
                          value: MixStyle.values.elementAt(i),
                          child: clueTxt(
                              "Color Mixture Style: ${MixStyle.values.elementAt(i).name}"),
                        )),
                onChanged: (MixStyle? value) {
                  widget.client.mixStyle = value!;
                },
              ),
              pad,
              Row(children: [
                clueTxt("Simple Squares: "),
                Checkbox(
                    value: widget.client.simpleSquares,
                    onChanged: (b) => widget.client.simpleSquares =
                        !widget.client.simpleSquares)
              ]),
              pad,
              Row(children: [
                clueTxt("Show Control Numbers: "),
                Checkbox(
                    value: showControl,
                    onChanged: (b) => setState(() => showControl = b ?? false))
              ]),
              pad,
              clueTxt("Guesses Remaining: ${game.guessesLeft}"),
              pad,
              IconButton(onPressed: () => showDialog(context: context,
                  builder: (BuildContext context) => SoundDialog(widget.client, context)),
                  icon: const Icon(Icons.music_note))
            ])));
  }

  Widget getBoard(ClueGame game, double? dialogWidth) {
    BoardMatrix? board = game.board;
    if (board == null) return const SizedBox.shrink();
    return Stack(fit: StackFit.loose, children: [
      getBoardImage(board,game.result),
      if (showControl && game.result == ClueResult.playing) getNumbers(board),
      getPieces(board, game.result, dialogWidth),
    ]);
  }

  Widget getPieces(BoardMatrix board,ClueResult result,double? dialogWidth) {
    return AspectRatio(aspectRatio: 1.0, child: GridView.count(crossAxisCount: 8, children:
      List.generate(64, (index) {
        final Widget boxChild;
        final p = board.squares[index].piece;
        if (p.type == PieceType.none) {
          boxChild = Container(color: const Color.fromARGB(0,0,0,0));
        } else if (p.type != PieceType.unknown) {
          boxChild = cb.ChessBoard.getPieceImage(PieceStyle.horsey.name,p.type.dartChessType,p.color.dartChessColor ?? cb.Color.WHITE);
        } else {
          Image pieceImg = Image(image: ZugUtils.getAssetImage(p.color == ChessColor.black ? "images/unknownB.png" :"images/unknownW.png"));
          boxChild = result == ClueResult.playing && !widget.client.playingClip ? InkWell(
            child: pieceImg,
            onTap: () => ChessDialogs.pieceDialog(p.color == ChessColor.white ? Piece.whitePieces : Piece.blackPieces,context,
                width: dialogWidth).then((piece) => widget.client.guessPiece(index,piece?.toLetter() ?? "?")),
          ) : pieceImg;
        }
        return DecoratedBox(decoration: BoxDecoration(border: Border.all(width: 1)), child: boxChild);
      })
    ));
  }
  
  Widget getNumbers(BoardMatrix board) {
    return AspectRatio(aspectRatio: 1.0, child: GridView.count(crossAxisCount: 8,children:
    List.generate(64, (index) => Align(alignment: Alignment.bottomLeft, child:
      Text(board.squares[index].control.totalControl.toString(),style: const TextStyle(color: Colors.white),))
    )
    ));
  }

  Widget getBoardImage(BoardMatrix board,ClueResult result) {
    return AspectRatio(aspectRatio: 1.0, child:
        result == ClueResult.playing
            ? (board.image != null ? RawImage(fit: BoxFit.cover, image: board.image) : const Text("Loading..."))
            : Image(image: ZugUtils.getAssetImage(result == ClueResult.won ? "images/winboard.png" : "images/loseboard.png"))
    );
  }

}
