import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zugclient/zug_client.dart';
import 'clue_client.dart';

enum ClueResult {won,lost,playing}

class ClueGame extends Area {
  final Map<int,Piece> _discoveredPieces = {};
  BoardMatrix? _board;
  int? guessesLeft;
  ClueResult result = ClueResult.playing;

  ClueGame(super.data);

  void updateGame(dynamic clueData,ClueClient? client) {
    guessesLeft = clueData[fieldGuessLeft];
    result = parseResult(clueData[fieldResult]) ?? ClueResult.playing;
    List<dynamic> controlData = clueData[fieldBoard][fieldControlList] ?? [];
    List<ControlTable> table = List.generate(controlData.length, (i) => ControlTable(controlData[i]["wc"],controlData[i]["bc"]));
    _board = BoardMatrix(
        fen: clueData[fieldBoard][fieldFEN],
        width: 360,
        height: 360,
        imageCallback: client!.imageReady,
        controlList: table,
        mixStyle: client.mixStyle,
        simple: client.simpleSquares);
    _discoveredPieces.clear();
    for (dynamic piece in clueData[fieldBoard][fieldPieces] ?? []) {
      int i = piece[fieldSqrIdx];
      Piece p = Piece.fromChar(piece[fieldPiece]);
      _discoveredPieces.putIfAbsent(i, () => p); //board?.squares[i].piece = p;
    }
    _setDiscoveredPieces();
  }

  void addDiscoveredPiece(int i, Piece p) {
    _discoveredPieces.putIfAbsent(i, () => p);
    _setDiscoveredPieces();
  }

  BoardMatrix? get board => _board;
  set board(BoardMatrix? matrix) {
    _board = matrix;
    _setDiscoveredPieces();
  }

  void _setDiscoveredPieces() {
    for (int i in _discoveredPieces.keys) {
      _board?.squares[i].piece = _discoveredPieces[i]!;
    }
  }

  ClueResult? parseResult(String result) {
    for (ClueResult clueResult in ClueResult.values) {
      if (clueResult.name == result) return clueResult;
    }
    return null;
  }
}