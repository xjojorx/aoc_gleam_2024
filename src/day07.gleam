import gleam/int
import gleam/io
import gleam/list
import gleam/string
import reader

type Operation {
  Value(Int)
  Add
  Multiply
  Concat
}

pub fn main() {
  // let input_text = reader.read_input("day07_ex")
  // let input_text = reader.read_input("day07_ex2")
  let input_text = reader.read_input("day07")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn parse1(input: String) -> List(#(Int, List(Int))) {
  string.split(input, "\n")
  |> list.filter(fn(x) { !string.is_empty(x) })
  |> list.map(fn(line) {
    let assert [test_value, values] = string.split(line, ":")
    let assert Ok(res) = int.parse(test_value)
    let operations =
      values
      |> string.split(" ")
      |> list.map(string.trim)
      |> list.filter(fn(x) { !string.is_empty(x) })
      |> list.map(fn(val) {
        let assert Ok(n) = int.parse(val)
        n
      })
    #(res, operations)
  })
}

fn part1(input: String) -> Int {
  let equations = parse1(input)

  equations
  |> list.filter(validate_equation)
  |> list.map(fn(eq) { eq.0 })
  |> int.sum
}

fn part2(input: String) -> Int {
  let equations = parse1(input)

  equations
  |> list.filter(validate_equation2)
  |> list.map(fn(eq) { eq.0 })
  |> int.sum
}

fn validate_equation(equation: #(Int, List(Int))) -> Bool {
  do_validate_equation(equation.0, equation.1, [], 0)
}

fn do_validate_equation(
  test_value: Int,
  values: List(Int),
  acc_opers: List(Operation),
  acc_res: Int,
) -> Bool {
  case values {
    _ if acc_res > test_value -> False
    [] -> acc_res == test_value
    [n, ..rest] -> {
      let val_add = acc_res + n
      let sol_add =
        do_validate_equation(test_value, rest, [Add, ..acc_opers], val_add)
      case sol_add {
        True -> True
        False ->
          do_validate_equation(
            test_value,
            rest,
            [Multiply, ..acc_opers],
            acc_res * n,
          )
      }
    }
  }
}

fn validate_equation2(equation: #(Int, List(Int))) -> Bool {
  do_validate_equation2(equation.0, equation.1, [], 0)
}

fn do_validate_equation2(
  test_value: Int,
  values: List(Int),
  acc_opers: List(Operation),
  acc_res: Int,
) -> Bool {
  case values {
    _ if acc_res > test_value -> False
    [] -> acc_res == test_value
    [n, ..rest] -> {
      let val_add = acc_res + n
      let sol_add =
        do_validate_equation2(test_value, rest, [Add, ..acc_opers], val_add)
      case sol_add {
        True -> True
        False -> {
          let mul_res =
            do_validate_equation2(
              test_value,
              rest,
              [Multiply, ..acc_opers],
              acc_res * n,
            )
          case mul_res {
            True -> True
            False -> {
              //concat
              let assert Ok(val_concat) =
                int.parse(int.to_string(acc_res) <> int.to_string(n))
              do_validate_equation2(
                test_value,
                rest,
                [Concat, ..acc_opers],
                val_concat,
              )
            }
          }
        }
      }
    }
  }
}
