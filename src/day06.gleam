import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/task
import gleam/result
import gleam/string
import reader

pub fn main() {
  let input_text = reader.read_input("day06_ex")
  // let input_text = reader.read_input("day06_ex2")
  // let input_text = reader.read_input("day06")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

type Mark {
  Guard(Dir)
  Empty
  Obstacle
  Visited
}

type Dir {
  Up
  Right
  Down
  Left
}

type Position =
  #(Int, Int)

type Map =
  Dict(Position, Mark)

fn part1(input: String) -> Int {
  let #(map, guard_pos, w, h) = parse_map(input)

  // io.debug(map|>dict.keys)
  let final_map = patrol(map, guard_pos, w, h)

  dict.values(final_map)
  |> list.count(fn(m) { m == Visited })
}

fn part2(input: String) -> Int {
  let #(map, guard_pos, w, h) = parse_map(input)
  // io.debug(map)

  let positions = dict.keys(map)
  let options =
    list.map(positions, fn(pos) {
      let assert Ok(content) = dict.get(map, pos)
      case content {
        Empty -> Some(dict.insert(map, pos, Obstacle))
        _ -> None
      }
    })
    |> list.filter_map(option.to_result(_, Nil))

  io.debug(list.length(options))

  let tasks =
    list.map(options, fn(opt) {
      task.async(fn() { check_loop(opt, guard_pos, w, h) })
    })

  let assert Ok(results) =
    task.try_await_all(tasks, 999_999_999_999)
    |> result.all
  list.count(results, fn(r) { r })
}

fn patrol(map: Map, guard_pos: Position, width: Int, height: Int) -> Map {
  let assert Ok(Guard(dir)) = dict.get(map, guard_pos)

  let visited = dict.insert(map, guard_pos, Visited)

  case guard_pos {
    #(0, _) -> visited
    #(_, 0) -> visited
    #(r, _) if r >= height - 1 -> visited
    #(_, c) if c >= width - 1 -> visited
    _ -> {
      let next_pos = case dir {
        Up -> #(guard_pos.0 - 1, guard_pos.1)
        Right -> #(guard_pos.0, guard_pos.1 + 1)
        Down -> #(guard_pos.0 + 1, guard_pos.1)
        Left -> #(guard_pos.0, guard_pos.1 - 1)
      }
      // let assert Ok(content) = dict.get(visited, next_pos)
      let content = case dict.get(visited, next_pos) {
        Ok(c) -> c
        Error(_) -> {
          io.debug(
            "failed "
            <> string.inspect(guard_pos)
            <> " next "
            <> string.inspect(next_pos)
            <> " (max_r: "
            <> string.inspect(height)
            <> ", max_c:"
            <> string.inspect(width)
            <> ")",
          )
          panic
        }
      }
      let #(next_dir, next_pos) = case content {
        Empty | Visited -> #(dir, next_pos)
        Obstacle ->
          case dir {
            Up -> #(Right, #(guard_pos.0, guard_pos.1 + 1))
            Right -> #(Down, #(guard_pos.0 + 1, guard_pos.1))
            Down -> #(Left, #(guard_pos.0, guard_pos.1 - 1))
            Left -> #(Up, #(guard_pos.0 - 1, guard_pos.1))
          }
        Guard(_) -> panic
      }

      let new_map = dict.insert(visited, next_pos, Guard(next_dir))
      patrol(new_map, next_pos, width, height)
    }
  }
}

fn check_loop(map: Map, guard_pos: Position, width: Int, height: Int) -> Bool {
  let assert Ok(Guard(dir)) = dict.get(map, guard_pos)

  let visited = dict.insert(map, guard_pos, Visited)

  let max_r = height - 1
  let max_c = width - 1
  case guard_pos {
    #(0, _) -> False
    #(_, 0) -> False
    #(r, _) if r >= max_r -> False
    #(_, c) if c >= max_c -> False
    _ -> {
      let next_pos = case dir {
        Up -> #(guard_pos.0 - 1, guard_pos.1)
        Right -> #(guard_pos.0, guard_pos.1 + 1)
        Down -> #(guard_pos.0 + 1, guard_pos.1)
        Left -> #(guard_pos.0, guard_pos.1 - 1)
      }

      // let assert Ok(content) = dict.get(visited, next_pos)
      let content = case dict.get(visited, next_pos) {
        Ok(c) -> c
        Error(_) -> {
          io.debug(
            "failed "
            <> string.inspect(guard_pos)
            <> " next "
            <> string.inspect(next_pos)
            <> " (max_r: "
            <> string.inspect(max_r)
            <> ", max_c:"
            <> string.inspect(max_c)
            <> ")",
          )
          panic
        }
      }

      let next = case content {
        Empty -> Ok(#(dir, next_pos))
        Obstacle ->
          case dir {
            Up -> Ok(#(Right, #(guard_pos.0, guard_pos.1 + 1)))
            Right -> Ok(#(Down, #(guard_pos.0 + 1, guard_pos.1)))
            Down -> Ok(#(Left, #(guard_pos.0, guard_pos.1 - 1)))
            Left -> Ok(#(Up, #(guard_pos.0 - 1, guard_pos.1)))
          }
        Visited -> Error(Nil)
        Guard(_) -> panic
      }

      case next {
        Error(_) -> True
        Ok(#(next_dir, next_pos)) -> {
          let new_map = dict.insert(visited, next_pos, Guard(next_dir))
          check_loop(new_map, next_pos, width, height)
        }
      }
    }
  }
}

fn parse_map(input: String) -> #(Map, Position, Int, Int) {
  let matrix =
    input
    |> string.split("\n")
    |> list.filter_map(fn(x) {
      case string.to_graphemes(x) {
        [] -> Error(Nil)
        l -> Ok(l)
      }
    })

  let h = list.length(matrix)
  let assert Ok(f) = list.first(matrix)
  let w = list.length(f)

  use map, row, i <- list.index_fold(matrix, #(dict.new(), #(-1, -1), w, h))
  use row_acc, item, j <- list.index_fold(row, map)
  let pos = #(i, j)

  let mark = parse_mark(item)
  let new_map = dict.insert(row_acc.0, pos, mark)
  case mark {
    Guard(_d) -> #(new_map, pos, w, h)
    _ -> #(new_map, row_acc.1, w, h)
  }
}

fn parse_mark(input: String) -> Mark {
  case input {
    "#" -> Obstacle
    "." -> Empty
    ">" -> Guard(Right)
    "^" -> Guard(Up)
    "v" -> Guard(Down)
    "<" -> Guard(Left)
    "x" | "X" -> Visited
    _ -> panic as "unexpected char"
  }
}
