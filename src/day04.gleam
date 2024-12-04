import gleam/io
import gleam/list
import gleam/string
import reader

pub fn main() {
  // let input_text = reader.read_input("day04_ex")
  // let input_text = reader.read_input("day04_ex2")
  let input_text = reader.read_input("day04")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn part1(input: String) -> Int {
  let matrix =
    input
    |> string.split("\n")
    |> list.map(string.to_graphemes)

  // use tot_acc, row, i <- list.index_fold(matrix, 0)
  // use row_acc, origin, j <- list.index_fold(row, 0)
  // explore(i, j, matrix)
  let horizontal =
    list.fold(matrix, 0, fn(acc, row) {
      let wins = list.window(row, 4)
      let n =
        list.count(wins, fn(w) {
          case w {
            ["X", "M", "A", "S"] -> True
            ["S", "A", "M", "X"] -> True
            _ -> False
          }
        })
      acc + n
    })
  // io.debug(horizontal)
  let vertical =
    list.fold(list.transpose(matrix), 0, fn(acc, row) {
      let wins = list.window(row, 4)
      let n =
        list.count(wins, fn(w) {
          case w {
            ["X", "M", "A", "S"] -> True
            ["S", "A", "M", "X"] -> True
            _ -> False
          }
        })
      acc + n
    })

  let rowset =
    list.window(matrix, 4)
    |> list.filter(fn(r) { list.length(r) == 4 })

  let diags = {
    use tot_acc, curr_rows <- list.fold(rowset, 0)

    //list of rows subdivided in windows
    let win = list.map(curr_rows, list.window(_, 4))
    let a = list.transpose(win)

    use sub_acc, curr <- list.fold(a, tot_acc)

    let d1 = case curr {
      [["X", _, _, _], [_, "M", _, _], [_, _, "A", _], [_, _, _, "S"]] -> 1
      _ -> 0
    }
    let d2 = case curr {
      [[_, _, _, "S"], [_, _, "A", _], [_, "M", _, _], ["X", _, _, _]] -> 1
      _ -> 0
    }
    let d3 = case curr {
      [["S", _, _, _], [_, "A", _, _], [_, _, "M", _], [_, _, _, "X"]] -> 1
      _ -> 0
    }
    let d4 = case curr {
      [[_, _, _, "X"], [_, _, "M", _], [_, "A", _, _], ["S", _, _, _]] -> 1
      _ -> 0
    }

    // io.debug([d1, d2, d3, d4])
    sub_acc + d1 + d2 + d3 + d4
  }
  io.debug("d")
  io.debug(diags)
  diags + horizontal + vertical
}

fn part2(input: String) {
  let matrix =
    input
    |> string.split("\n")
    |> list.map(string.to_graphemes)

  // let rowset = list.window(matrix, 3)
  //   |> list.filter(fn(r){ list.length(r) == 3 })
  //
  //
  // use tot_acc, curr_rows <- list.fold(rowset, 0)
  //
  // //list of rows subdivided in windows
  // let win = list.map(curr_rows, list.window(_, 3)) 
  // let a = list.transpose(win)
  //
  // // io.debug("this:")
  // // io.debug(a)
  //

  let a = to_square_windows(matrix, 3)
  let tot_acc = 0

  use sub_acc, curr <- list.fold(a, tot_acc)

  let found = case curr {
    [["M", _, "M"], [_, "A", _], ["S", _, "S"]] -> True
    [["M", _, "S"], [_, "A", _], ["M", _, "S"]] -> True
    [["S", _, "S"], [_, "A", _], ["M", _, "M"]] -> True
    [["S", _, "M"], [_, "A", _], ["S", _, "M"]] -> True
    _ -> False
  }

  case found {
    True -> sub_acc + 1
    False -> sub_acc
  }
}

fn to_square_windows(matrix: List(List(a)), size: Int) {
  let rowset =
    list.window(matrix, size)
    |> list.filter(fn(r) { list.length(r) == size })

  list.flat_map(rowset, fn(curr_rows) {
    let win = list.map(curr_rows, list.window(_, size))
    let a = list.transpose(win)
  })
}
