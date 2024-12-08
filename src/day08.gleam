import gleam/yielder.{Next}
import gleam/set.{type Set}
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/string
import gleam/option.{None, Some}
import reader


type Position {
  Position(row: Int, col: Int)
}

type Map {
  Map(antennas: Dict(String, List(Position)), width: Int, height: Int)
}

pub fn main() {
  // let input_text = reader.read_input("day08_ex")
  // let input_text = reader.read_input("day08_ex2")
  let input_text = reader.read_input("day08")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn part1(input: String) -> Int {
  let map = parse(input)

  dict.keys(map.antennas)
  |> list.map(get_antinodes(map, _))
  |> union_sets
  |> set.size

  // let antinodes = list.map(dict.keys(map.antennas), get_antinodes(map, _))
}
fn union_sets(sets: List(Set(a))) -> Set(a) {
  list.fold(sets, set.new(), set.union)

}

fn get_antinodes(map: Map, antenna: String) -> Set(Position) {
  let assert Ok(positions) = dict.get(map.antennas, antenna)
  do_get_antinodes(positions, map.width, map.height, set.new())
}
fn do_get_antinodes(antennas: List(Position), width: Int, height: Int, acc: Set(Position)) -> Set(Position) {
  case antennas {
    [] -> acc
    [ant, ..rest] -> {
      let new_set = list.fold(rest, acc, fn(set_acc, x) {
        let delta_col = x.col - ant.col
        let delta_row = x.row - ant.row
        let antinode_fwd = Position(x.row + delta_row, x.col + delta_col)

        let fwd = case antinode_fwd {
          Position(r, _) if r >= height || r < 0 -> set_acc
          Position(_, c) if c >= width  || c < 0 -> set_acc
          _ -> set.insert(set_acc, antinode_fwd)
        }

        let antinode_bck = Position(ant.row - delta_row, ant.col - delta_col)
        let bck = case antinode_bck {
          Position(r, _) if r >= height || r < 0 -> fwd
          Position(_, c) if c >= width  || c < 0 -> fwd
          _ -> set.insert(fwd, antinode_bck)
        }
      })

      do_get_antinodes(rest, width, height, new_set)
    }
  }
}

fn part2(input: String) -> Int {
  let map = parse(input)

  dict.keys(map.antennas)
  |> list.map(get_antinodes2(map, _))
  |> union_sets
  |> set.size
}

fn get_antinodes2(map: Map, antenna: String) -> Set(Position) {
  let assert Ok(positions) = dict.get(map.antennas, antenna)
  let start = set.from_list(positions) // now all antennas are antinodes
  do_get_antinodes2(positions, map.width, map.height, start)
}
fn do_get_antinodes2(antennas: List(Position), width: Int, height: Int, acc: Set(Position)) -> Set(Position) {
  case antennas {
    [] -> acc
    [ant, ..rest] -> {
      let new_set = list.fold(rest, acc, fn(set_acc, x) {
        let antis = antinodes_for_pair(ant, x, width, height)
        set.union(set_acc, antis)
      })

      do_get_antinodes2(rest, width, height, new_set)
    }
  }
}
fn position_in_map(p: Position, w: Int, h: Int) -> Bool {
  case p {
    Position(r, _) if r >= h || r < 0 -> False
    Position(_, c) if c >= w  || c < 0 -> False
    _ -> True
  }
}
fn antinodes_for_pair(a1: Position, a2: Position, width: Int, height: Int) -> Set(Position) {
  let delta_col = a2.col - a1.col
  let delta_row = a2.row - a1.row

  // let max_times = int.max(width/delta_col, height/delta_row)
  yielder.unfold(1, fn(n) {
    let antinode_fwd = Position(a2.row + {delta_row * n}, a2.col + {delta_col * n})
    let antinode_bck = Position(a1.row - {delta_row * n}, a1.col - {delta_col * n})

    let val = [antinode_fwd, antinode_bck]|> list.filter(position_in_map(_, width, height))

    case val {
      [] -> yielder.Done
    _ ->Next(set.from_list(val), n+1)
    }
  })
  |> yielder.fold(set.new(), set.union)
}

fn parse(input: String) -> Map {
  let matrix =
    string.split(input, "\n")
    |> list.filter_map(fn(line) {
      let trimmed = string.trim(line)
      case trimmed {
        "" -> Error(Nil)
        _ -> Ok(string.to_graphemes(line))
      }
    })

  let antennas = {
    use acc, line, row <- list.index_fold(matrix, dict.new())
    use row_acc, char, col <- list.index_fold(line, acc)
    case char {
      "." -> row_acc
      c -> dict.upsert(row_acc, c, fn(x) {
        case x {
          Some(val) -> list.append(val, [Position(row, col)])
          None -> [Position(row,col)]
        }
      })
    }
  }
  let assert Ok(fst) = list.first(matrix)
  Map(antennas, list.length(fst),list.length(matrix))
}
