import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/dialogs.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zug_utils/zug_utils.dart';
import 'clue_client.dart';
import 'clue_game.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;

class ClueBoardWidget extends StatelessWidget {
  final ClueClient client;
  final bool showControl;
  final ClueGame game;
  final double boardSize;

  const ClueBoardWidget(this.client,this.game,this.showControl,this.boardSize,{super.key});

  @override
  Widget build(BuildContext context) {
    BoardMatrix? board = game.board;
    if (board == null) return const SizedBox.shrink();
    return game.result == ClueResult.playing
        ? getBoard(board,context,min(800,boardSize))
        : InkWell(child: getBoard(board,context,min(800,boardSize)),
        onTap: () => client.areaCmd(ClueMsg.newBoard));


  }

  Widget getBoard(BoardMatrix board, BuildContext context, double dialogWidth) {
    return Stack(fit: StackFit.loose, children: [
      getBoardImage(board, game.result),
      if (showControl && game.result == ClueResult.playing) getNumbers(board),
      getPieces(board, game.result, context, dialogWidth),
    ]);
  }


  Widget getBoardImage(BoardMatrix board, ClueResult result) {
    return AspectRatio(
        aspectRatio: 1.0,
        child: result == ClueResult.playing
            ? RawImage(fit: BoxFit.cover, image: board.image)
            : Image(
            image: ZugUtils.getAssetImage(result == ClueResult.won
                ? "images/winboard.png"
                : "images/loseboard.png")));
  }

  Widget getPieces(BoardMatrix board,ClueResult result, BuildContext context, double? dialogWidth) {
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
        boxChild = result == ClueResult.playing ? InkWell(
          child: pieceImg,
          onTap: () => ChessDialogs.pieceDialog(p.color == ChessColor.white ? Piece.whitePieces : Piece.blackPieces,context,
              width: dialogWidth).then((piece) => client.guessPiece(index,piece?.toLetter() ?? "?")),
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

}
