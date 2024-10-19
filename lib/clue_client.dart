import 'dart:developer';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zugclient/oauth_client.dart';
import 'package:zugclient/zug_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:zugclient/zug_fields.dart';

import 'clue_game.dart';

enum ClueMsg { guess, goodGuess, badGuess, newBoard, gameWin, gameLose }
const fieldBoard = "board";
const fieldSquare = "square";
const fieldPiece = "piece";
const fieldPieces = "pieces";
const fieldFEN = "fen";
const fieldControlList = "controlList";
const fieldGuessLeft = "guess_left";
const fieldResult = "result";
const fieldSqrIdx = "sqr_idx";

class ClueClient extends ZugClient {

  ClueGame get currentGame => currentArea as ClueGame;

  MixStyle _mixStyle = MixStyle.additive;
  MixStyle get mixStyle => _mixStyle;
  set mixStyle(MixStyle m) {
    _mixStyle = m;
    refreshBoard();
  }

  bool _simpleSquares = false;
  bool get simpleSquares => _simpleSquares;
  set simpleSquares(bool b) {
    _simpleSquares = b;
    refreshBoard();
  }

  ClueClient(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.localServer}) { showServMess = true;
    clientName = "clue_client";
    addFunctions({  //ClueMsg.newBoard: handleNewBoard,
      ClueMsg.gameWin: handleVictory,
      ClueMsg.gameLose: handleDefeat,
      ClueMsg.goodGuess: handleGoodGuess,
      ClueMsg.badGuess: handleBadGuess,
    });
    checkRedirect(OauthClient("lichess.org",clientName));
    loadPieceImages(PieceStyle.horsey);
  }

  void refreshBoard() {
    if (currentGame.board != null) {
      currentGame.board = BoardMatrix(
        fen: currentGame.board!.fen,
        width: currentGame.board!.width,
        height: currentGame.board!.height,
        imageCallback: imageReady,
        controlList: currentGame.board!.controlList,
        mixStyle: mixStyle,
        simple: simpleSquares);
    }
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
      game.updateGame(data, this);
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
      game.addDiscoveredPiece(data[fieldSquare], Piece.fromChar(data[fieldPiece]));
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

  void loadPieceImages(PieceStyle pieceStyle) {
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