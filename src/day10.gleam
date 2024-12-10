import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import reader

pub fn main() {
  // let input_text = reader.read_input("day10_ex")
  // let input_text = reader.read_input("day10_ex2")
  let input_text = reader.read_input("day10")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

type Map {
  Map(grid: Dict(Position, Int), rows: Int, cols: Int)
}

type Position =
  #(Int, Int)

fn part1(input: String) -> Int {
  let map = parse(input)

  let starts =
    map.grid
    |> dict.filter(fn(_k, v) { v == 0 })
    |> dict.keys()

  let scores = list.map(starts, fn(head) { explore_trail(head, map) })

  int.sum(scores)
}

fn explore_trail(head: Position, map: Map) -> Int {
  do_explore_trail([head], map, set.new())
}

fn do_explore_trail(
  heads: List(Position),
  map: Map,
  ends: set.Set(Position),
) -> Int {
  case heads {
    [] -> set.size(ends)
    [curr, ..rest] -> {
      let assert Ok(val) = dict.get(map.grid, curr)
      // io.debug(curr)
      // io.debug(val)
      let next = val + 1

      let nexts =
        get_neighbours(map, curr)
        |> list.filter_map(fn(neighbor) {
          case neighbor {
            #(_pos, val) if val != next -> Error(Nil)
            #(pos, _val) -> Ok(pos)
          }
        })

      case next {
        9 -> {
          let new_ends = set.from_list(nexts) |> set.union(ends)
          do_explore_trail(rest, map, new_ends)
        }
        _ -> do_explore_trail(list.append(rest, nexts), map, ends)
      }
    }
  }
}

fn get_neighbours(map: Map, pos: Position) -> List(#(Position, Int)) {
  [#(-1, 0), #(0, 1), #(1, 0), #(0, -1)]
  |> list.filter_map(fn(x) {
    case x.0 + pos.0, x.1 + pos.1 {
      r, c if r < 0 || c < 0 -> Error(Nil)
      r, _ if r >= map.rows -> Error(Nil)
      _, c if c >= map.cols -> Error(Nil)
      r, c -> {
        let assert Ok(val) = dict.get(map.grid, #(r, c))
        Ok(#(#(r, c), val))
      }
    }
  })
}

fn parse(input: String) -> Map {
  let lines =
    input
    |> string.trim
    |> string.split("\n")

  let grid =
    lines
    |> list.index_fold(dict.new(), fn(acc, line, row_n) {
      line
      |> string.trim
      |> string.to_graphemes
      |> list.map(reader.parse_int)
      |> list.index_fold(acc, fn(row_acc, val, col_n) {
        dict.insert(row_acc, #(row_n, col_n), val)
      })
    })

  let rows = list.length(lines)
  let assert Ok(fst) = list.first(lines)
  let cols = string.length(fst)

  Map(grid, rows, cols)
}

fn part2(input: String) -> Int {
  let map = parse(input)

  let starts =
    map.grid
    |> dict.filter(fn(_k, v) { v == 0 })
    |> dict.keys()

  let scores = list.map(starts, fn(head) { explore_trail2(head, map) })

  int.sum(scores)
}

fn explore_trail2(head: Position, map: Map) -> Int {
  do_explore_trail2([head], map, 0)
}

fn do_explore_trail2(heads: List(Position), map: Map, ends: Int) -> Int {
  case heads {
    [] -> ends
    [curr, ..rest] -> {
      let assert Ok(val) = dict.get(map.grid, curr)
      // io.debug(curr)
      // io.debug(val)
      let next = val + 1

      let nexts =
        get_neighbours(map, curr)
        |> list.filter_map(fn(neighbor) {
          case neighbor {
            #(_pos, val) if val != next -> Error(Nil)
            #(pos, _val) -> Ok(pos)
          }
        })

      case next {
        9 -> {
          let new_ends = list.length(nexts)
          do_explore_trail2(rest, map, ends + new_ends)
        }
        _ -> do_explore_trail2(list.append(rest, nexts), map, ends)
      }
    }
  }
}
