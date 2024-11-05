import 'dart:developer';
import 'dart:math' as math;
import 'package:clue_client/dialogs.dart';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:zugclient/zug_fields.dart';
import 'clue_game.dart';

enum ClueMsg { guess, goodGuess, badGuess, newBoard, gameWin, gameLose,
  startTimer, startedUnfixed, startedFixed, abortTimer, stopUnfixed, stopFixed, top, scoreRank }

class TimerData {
  final int? seconds, boards;
  const TimerData(this.seconds,this.boards);
}

enum TimerMode {
  threeMinutes(TimerData(180,null)),
  fiveMinutes(TimerData(300,null)),
  tenMinutes(TimerData(600,null)),
  threeBoards(TimerData(null,3)),
  fiveBoards(TimerData(null,5)),
  twelveBoards(TimerData(null,12));
  final TimerData timerData;
  const TimerMode(this.timerData);
  @override
  String toString() {
    return name.substring(0,1).toUpperCase() + name.substring(1);
  }
  dynamic toJSON() {
    if (timerData.seconds != null) return { fieldSeconds : timerData.seconds };
    if (timerData.boards != null) return { fieldBoards : timerData.boards };
  }
}

const fieldBoard = "board";
const fieldSquare = "square";
const fieldPiece = "piece";
const fieldPieces = "pieces";
const fieldFEN = "fen";
const fieldControlList = "controlList";
const fieldGuessLeft = "guess_left";
const fieldResult = "result";
const fieldSqrIdx = "sqr_idx";
const fieldBoards = "boards";
const fieldSeconds = "seconds";
const fieldTimed = "timed";

class ClueClient extends ZugClient {

  final tutorialLink = "https://youtu.be/HXax_lNH7oU"; //"https://youtu.be/LXfKUw4ondg";
  final discoLink = "https://discord.gg/XutMjUD7jY";
  final int numTracks = 4;

  ClueGame get currentGame => currentArea as ClueGame;

  MixStyle _mixStyle = MixStyle.light;
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

  bool _showControl = false;
  bool get showControl => _showControl;
  set showControl(bool b) {
    _showControl = b;
    refreshBoard();
  }

  final defFixedTime = false;

  TimerMode timerMode = TimerMode.threeBoards;

  ClueClient(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.localServer}) { showServMess = true;
    clientName = "clue_client";
    addFunctions({  //ClueMsg.newBoard: handleNewBoard,
      ClueMsg.gameWin: handleVictory,
      ClueMsg.gameLose: handleDefeat,
      ClueMsg.goodGuess: handleGoodGuess,
      ClueMsg.badGuess: handleBadGuess,
      ClueMsg.startedUnfixed : handleCountUp,
      ClueMsg.stopUnfixed : handleTimerComplete,
      ClueMsg.startedFixed : handleCountDown,
      ClueMsg.stopFixed : handleTimerComplete,
      ClueMsg.abortTimer : handleAbortTimer,
      ClueMsg.top : handleTop,
      ClueMsg.scoreRank : handleScoreRank,
    });
    if (prefs?.getBool(AudioType.sound.name) == null) {
      prefs?.setBool(AudioType.sound.name,true);
    }
    checkRedirect("lichess.org");
    loadPieceImages(PieceStyle.horsey);

  }

  @override
  void connected() {
    IntroDialog(zugAppNavigatorKey.currentContext!,tutorialLink,discoLink).raise().then((b) {
      prefs?.setBool(AudioType.music.name,b ?? false);
      playMusic("clue_track_1");
    });
    super.connected();
  }

  void playMusic(String track) {
    ZugClient.log.info("Playing track: $track");
    playTrack(track)?.future.then((b) {
      ZugClient.log.info("Finished track: $track");
      playMusic(getRndTrack(track));
    });
  }

  String getRndTrack(String currentTrack) {
    String track;
    do {
      track = "clue_track_${(math.Random().nextInt(numTracks)+1).toString()}";
    } while(track == currentTrack);
    return track;
  }

  //bool isFixedTime() { return prefs?.getBool("fixed_time") ?? defFixedTime; }

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
    for (final area in areas) { //print("${area[fieldTitle]} - ${userName.toString()}");
      if (area[fieldTitle] == userName.toString()) {
        inGame = true;
        switchArea(area[fieldTitle]);

      }
    }
    if (!inGame) newArea(title: userName.toString());
    return true;
  }

  @override
  bool handleUpdateArea(data, {Area? clueGame}) { //print("Update: $data");
    Area game = clueGame ?? getOrCreateArea(data);
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
      playClip("ding",interruptTrack: false);
      update();
    }
  }

  void handleBadGuess(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame && game == currentArea) {
      game.guessesLeft = data[fieldGuessLeft];
      playClip("doink",interruptTrack: false);
      update();
    }
  }

  Future<void> handleVictory(data) async {
    handleUpdateArea(data);
    playClip("victory");

  }

  Future<void> handleDefeat(data) async {
    handleUpdateArea(data);
    playClip("defeat");
  }

  void handleCountUp(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame) {
      game.countUp = 0;
      update();
    }
  }

  void handleCountDown(data) {
    Area game = getOrCreateArea(data);
    if (game is ClueGame) {
      game.countDown = data[fieldSeconds];
      update();
    }
  }

  void handleTimerComplete(data) { //InfoDialog(zugAppNavigatorKey.currentContext!,data.toString()).raise();
    Area game = getOrCreateArea(data);
    if (game is ClueGame) {
      game.endTimer();
      update();
    }
  }

  void handleAbortTimer(data) { //InfoDialog(zugAppNavigatorKey.currentContext!,data.toString()).raise();
    Area game = getOrCreateArea(data);
    if (game is ClueGame) {
      game.endTimer();
      update();
    }
  }

  void handleTop(data) {
    TopDialog(zugAppNavigatorKey.currentContext!,data["scores"] as List<dynamic>).raise();
  }

  void handleScoreRank(data) {
    InfoDialog(zugAppNavigatorKey.currentContext!,
        "Your score ranks ${getPlace(data["rank"])} (out of ${data["scores"]})").raise();
  }

  String getPlace(int i) {
    if (i == 1) return "first";
    if (i == 2) return "second";
    if (i == 3) return "third";
    return "${i}th";
  }

  guessPiece(int sqr, String? pieceLetter) {
    if (pieceLetter != null) {
      areaCmd(ClueMsg.guess, data: {fieldSquare: sqr, fieldPiece: pieceLetter});
    }
  }

  startTimer(TimerMode mode) {
    areaCmd(ClueMsg.startTimer,data: mode.toJSON());
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

}