import gleam/int
import gleam/io
import gleam/list
import gleam/string
import reader

pub fn main() {
  // let input_text = reader.read_input("day02_ex")
  let input_text = reader.read_input("day02")
  let lines =
    string.split(input_text, "\n")
    |> list.filter(fn(l) { !string.is_empty(l) })
    |> list.map(fn(l) {
      let resints =
        string.split(l, " ")
        |> list.map(string.trim)
        |> list.try_map(int.parse)
      let assert Ok(nums) = resints
      nums
    })

  let res =
    lines
    |> list.filter(is_safe)
    |> list.length

  io.println("Part 1: " <> string.inspect(res))

  let res =
    lines
    |> list.filter(is_safe_removing(_, 1))
    |> list.length

  io.println("Part 2: " <> string.inspect(res))
}

fn is_safe(line: List(Int)) -> Bool {
  let pairs = list.window_by_2(line)

  let assert Ok(fst) = list.first(pairs)
  let asc = fst.0 < fst.1

  list.all(pairs, fn(pair) {
    let dir = case asc {
      True -> pair.0 < pair.1
      False -> pair.0 > pair.1
    }

    let diff = int.absolute_value(pair.0 - pair.1)

    dir && diff <= 3 && diff >= 1
  })
}

fn is_safe_removing(line: List(Int), removing: Int) -> Bool {
  line
  |> list.combinations(list.length(line) - removing)
  |> list.any(is_safe)
}
