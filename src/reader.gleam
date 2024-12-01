import simplifile.{read}

pub fn read_input(name: String) -> String {
  let path = "inputs/"<>name

  let assert Ok(contents) = read(path)

  contents
}
