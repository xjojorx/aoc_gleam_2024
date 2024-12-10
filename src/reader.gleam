import gleam/int
import simplifile.{read}

pub fn read_input(name: String) -> String {
  let path = "inputs/" <> name

  let assert Ok(contents) = read(path)

  contents
}

pub fn parse_int(str: String) -> Int {
  let assert Ok(n) = int.parse(str)
  n
}
