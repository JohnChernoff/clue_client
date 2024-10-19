import 'dart:developer';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zugclient/oauth_client.dart';
import 'package:zugclient/zug_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:zugclient/zug_fields.dart';

enum ClueMsg { guess, goodGuess, badGuess, newBoard, gameWin, gameLose }
enum ClueResult {won,lost,playing}
const fieldBoard = "board";
const fieldSquare = "square";
const fieldPiece = "piece";
const fieldPieces = "pieces";
const fieldFEN = "fen";
const fieldControlList = "controlList";
const fieldGuessLeft = "guess_left";
const fieldResult = "result";
const fieldSqrIdx = "sqr_idx";

class ClueGame extends Area {
  BoardMatrix? board;
  int? guessesLeft;
  ClueResult result = ClueResult.playing;
  ClueGame(super.data);
}

class ClueClient extends ZugClient {

  

  ClueClient(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.localServer}) { showServMess = true;
    clientName = "clue_client";
    addFunctions({  //ClueMsg.newBoard: handleNewBoard,
      ClueMsg.gameWin: handleVictory,
      ClueMsg.gameLose: handleDefeat,
      ClueMsg.goodGuess: handleGoodGuess,
      ClueMsg.badGuess: handleBadGuess,
    });
    checkRedirect(OauthClient("lichess.org",clientName));
    setPieces(PieceStyle.horsey);

  }

  @override
  bool handleAreaList(data) {
    super.handleAreaList(data);
    List<dynamic> areas = data[fieldAreas];
    bool inGame = false;
    for (final area in areas) {
      print("${area[fieldTitle]} - ${userName.toString()}");
      if (area[fieldTitle] == userName.toString()) {
        inGame = true;
        switchArea(area[fieldTitle]);

      }
    }
    if (!inGame) newArea(title: userName.toString());
    return true;
  }

  @override
  bool handleUpdateArea(data) { //print("Update: $data");
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      List<dynamic> controlData = data[fieldBoard][fieldControlList] ?? [];
      List<ControlTable> table = List.generate(controlData.length, (i) => ControlTable(controlData[i]["wc"],controlData[i]["bc"]));
      final matrix = BoardMatrix(data[fieldBoard][fieldFEN], 360, 360, imageReady, controlList: table, mixStyle: MixStyle.pigment, simple: true); //, mixStyle: MixStyle.add);
      List<dynamic> pieceList = data[fieldBoard][fieldPieces] ?? [];
      for (dynamic piece in pieceList) {
        matrix.squares[piece[fieldSqrIdx]].piece = Piece.fromChar(piece[fieldPiece]);
      }
      game.board = matrix;
      game.guessesLeft = data[fieldGuessLeft];
      game.result = parseResult(data[fieldResult]) ?? ClueResult.playing;
    }
    return false; //wait for image
  }

  ClueResult? parseResult(String result) {
    for (ClueResult clueResult in ClueResult.values) {
      if (clueResult.name == result) return clueResult;
    }
    return null;
  }

  @override
  Area createArea(data) {
    return ClueGame(data);
  }

  void imageReady(img) { //print(board); print(img);
    update();
  }

  void handleGoodGuess(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      game.board?.squares[data[fieldSquare]].piece = Piece.fromChar(data[fieldPiece]); //slightly redundant now
      playClip("ding");
      update();
    }
  }

  void handleBadGuess(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      game.guessesLeft = data[fieldGuessLeft];
      playClip("doink");
      update();
    }
  }

  void handleVictory(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      game.result = ClueResult.won;
      update();
    }
  }

  void handleDefeat(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      game.result = ClueResult.lost;
      update();
    }
  }

  guessPiece(int sqr, String pieceLetter) {
    areaCmd(ClueMsg.guess,data: {
        fieldSquare : sqr,
        fieldPiece : pieceLetter
    });
  }

  void setPieces(PieceStyle pieceStyle) {
    for (PieceType t in PieceType.values) {
      if (t != PieceType.none && t != PieceType.unknown) {
        final wPieceImg = cb.ChessBoard.getPieceImage(pieceStyle.name,t.dartChessType,cb.Color.WHITE);
        Piece.imgMap.update(Piece(t,ChessColor.white).toString(), (i) => wPieceImg, ifAbsent: () => wPieceImg);
        final bPieceImg = cb.ChessBoard.getPieceImage(pieceStyle.name,t.dartChessType,cb.Color.BLACK);
        Piece.imgMap.update(Piece(t,ChessColor.black).toString(), (i) => bPieceImg, ifAbsent: () => bPieceImg);
      }
    }
    log("Loaded Pieces");
  }

  @override
  bool soundCheck() {
    return true;
  }

}