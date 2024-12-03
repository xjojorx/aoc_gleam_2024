import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp.{type Match, Match}
import gleam/string
import reader

pub fn main() {
  // let input_text = reader.read_input("day03_ex")
  // let input_text = reader.read_input("day03_ex2")
  let input_text = reader.read_input("day03")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))

  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn part1(input: String) -> Int {
  let assert Ok(r) = regexp.from_string("mul\\((\\d{1,3}),(\\d{1,3})\\)")
  let matches = regexp.scan(r, input)
  list.fold(matches, 0, fn(acc, m) {
    let assert [Some(m1s), Some(m2s)] = m.submatches
    let assert Ok(m1) = int.parse(m1s)
    let assert Ok(m2) = int.parse(m2s)
    let curr = m1 * m2
    acc + curr
  })
}

type Instruction {
  Mul(Int, Int)
  Do
  Dont
}

fn part2(input: String) -> Int {
  let assert Ok(r) =
    regexp.from_string("mul\\((\\d{1,3}),(\\d{1,3})\\)|do\\(\\)|don't\\(\\)")

  regexp.scan(r, input)
  |> list.map(parse_match)
  |> evaluate
}

fn parse_match(match: Match) -> Instruction {
  case match |> io.debug {
    Match("do()", _) -> Do
    Match("don't()", _) -> Dont
    Match(_, [Some(m1s), Some(m2s)]) -> {
      let assert Ok(m1) = int.parse(m1s)
      let assert Ok(m2) = int.parse(m2s)
      Mul(m1, m2)
    }
    _ -> panic as "unexpected match"
  }
}

fn evaluate(instructions: List(Instruction)) -> Int {
  do_evaluate(instructions, True, 0)
}

fn do_evaluate(instructions: List(Instruction), mode: Bool, acc: Int) -> Int {
  case instructions {
    [] -> acc
    [Do, ..rest] -> do_evaluate(rest, True, acc)
    [Dont, ..rest] -> do_evaluate(rest, False, acc)
    [Mul(m1, m2), ..rest] ->
      case mode {
        True -> do_evaluate(rest, mode, acc + { m1 * m2 })
        False -> do_evaluate(rest, mode, acc)
      }
  }
}
