import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/dialogs.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_utils.dart';
import 'clue_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'clue_game.dart';

class MainPage extends StatefulWidget {
  final ClueClient client;
  const MainPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();

}

class _MainPageState extends State<MainPage> {
  bool showControl = false;

  @override
  void initState() {
    widget.client.areaCmd(ClientMsg.setDeaf,data:{fieldDeafened:false});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.client.currentArea as ClueGame;
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints contraints) {
      double dim = min(contraints.maxHeight - 128,contraints.maxWidth - 32);
      return Center(
        child: SizedBox(
          width: dim, height: dim,
          child: Column(
            children: [
              Row(children: [
                const Text("Simple Squares: "),
                Checkbox(value: widget.client.simpleSquares, onChanged: (b) => widget.client.simpleSquares = !widget.client.simpleSquares),
                const Text("Show Control Numbers: "),
                Checkbox(value: showControl, onChanged: (b) => setState(() => showControl = b ?? false)),
                Text("Guesses Remaining: ${game.guessesLeft}"),
              ]),
              Expanded(child:  game.result == ClueResult.playing
                  ? getGameWidget(game)
                  : InkWell(child: getGameWidget(game),onTap: () => widget.client.areaCmd(ClueMsg.newBoard)) ),
            ],
          ),
        )
      );
    });
  }

  Widget getGameWidget(ClueGame game) {
    BoardMatrix? board = game.board;
    if (board == null) return const SizedBox.shrink();
    return Stack(fit: StackFit.loose, children: [
      getBoardImage(board,game.result),
      if (showControl && game.result == ClueResult.playing) getNumbers(board),
      getPieces(board, game.result),
    ]);
  }

  Widget getPieces(BoardMatrix board,ClueResult result) {
    return AspectRatio(aspectRatio: 1.0, child: GridView.count(crossAxisCount: 8,children:
      List.generate(64, (index) {
        final Widget boxChild;
        final p = board.squares[index].piece;
        if (p.type == PieceType.none) {
          boxChild = Container(color: const Color.fromARGB(0,0,0,0));
        } else if (p.type != PieceType.unknown) {
          boxChild = cb.ChessBoard.getPieceImage(PieceStyle.horsey.name,p.type.dartChessType,p.color.dartChessColor ?? cb.Color.WHITE);
        } else {
          Image pieceImg = Image(image: ZugUtils.getAssetImage(p.color == ChessColor.black ? "images/unknownB.png" :"images/unknownW.png"));
          boxChild = result == ClueResult.playing ? InkWell(
            child: pieceImg,
            onTap: () => ChessDialogs.pieceDialog(p.color == ChessColor.white ? Piece.whitePieces : Piece.blackPieces,context)
                .then((piece) => widget.client.guessPiece(index,piece?.toLetter() ?? "?")),
          ) : pieceImg;
        }
        return DecoratedBox(decoration: BoxDecoration(border: Border.all(width: 1)), child: boxChild);
      })
    ));
  }
  
  Widget getNumbers(BoardMatrix board) {
    return AspectRatio(aspectRatio: 1.0, child: GridView.count(crossAxisCount: 8,children:
    List.generate(64, (index) => Align(alignment: Alignment.bottomLeft, child: Text(board.squares[index].control.totalControl.toString(),style: const TextStyle(color: Colors.white),))
    )
    ));
  }

  Widget getBoardImage(BoardMatrix board,ClueResult result) {
    return AspectRatio(aspectRatio: 1.0, child:
        result == ClueResult.playing
            ? (board.image != null ? RawImage(fit: BoxFit.cover, image: board.image) : const Text("Loading..."))
            : Image(image: ZugUtils.getAssetImage("images/clueboard.png"))
    );
  }
}