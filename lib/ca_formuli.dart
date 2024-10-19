abstract class CaTicker {
  List<List<int>> nextTick(List<List<int>> cells);
}

class LifeMatrix implements CaTicker {

  @override
  List<List<int>> nextTick(List<List<int>> cells) {
    List<List<int>> newCells = List.generate(cells.length, (y) =>
        List.generate(cells[y].length, (x) => cells[x][y]));
    for (int y = 0; y < cells.length; y++) {
      for (int x =0; x < cells[y].length; x++) {

      }
    }
    return newCells;
  }
}