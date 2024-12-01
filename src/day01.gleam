import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder
import reader

pub fn main() {
  // let input_text = reader.read_input("day01_ex")
  let input_text = reader.read_input("day01")
  let lines =
    string.split(input_text, "\n") |> list.filter(fn(l) { !string.is_empty(l) })
  let pairs =
    lines
    |> list.map(fn(line) {
      let assert Ok(#(s1, s2)) = string.split_once(line, " ")
      let assert Ok(n1) = int.parse(s1 |> string.trim)
      let assert Ok(n2) = int.parse(s2 |> string.trim)
      #(n1, n2)
    })

  let #(l1, l2) = list.unzip(pairs)

  let res = part1(l1, l2)
  io.println("part1: " <> string.inspect(res))

  let res = part2(l1, l2)
  io.println("part2: " <> string.inspect(res))
}

fn part1(l1: List(Int), l2: List(Int)) -> Int {
  let l1 = list.sort(l1, int.compare)
  let l2 = list.sort(l2, int.compare)

  list.zip(l1, l2)
  |> list.fold(0, fn(acc, pair) { acc + int.absolute_value(pair.0 - pair.1) })
}

fn part2(l1: List(Int), l2: List(Int)) -> Int {
  let freqs = freq_list(l2)

  use acc, item <- list.fold(l1, 0)
  case dict.get(freqs, item) {
    Ok(n) -> acc + { item * n }
    Error(_) -> acc
  }
}

fn freq_list(l: List(Int)) -> Dict(Int, Int) {
  yielder.from_list(l)
  |> yielder.group(fn(it) { it })
  |> dict.map_values(fn(_k, v) { list.length(v) })
}
