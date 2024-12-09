import gleam/int
import gleam/io
import gleam/list
import gleam/string
import reader

type Block {
  Empty
  FileBlock(id: Int)
}

pub fn main() {
  // let input_text = reader.read_input("day09_ex")
  // let input_text = reader.read_input("day09_ex2")
  let input_text = reader.read_input("day09")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn part1(input: String) -> Int {
  let disk = parse(input)

  let def_disk = defrag_block(disk)

  list.index_fold(def_disk, 0, fn(acc, block, i) {
    case block {
      Empty -> acc
      FileBlock(id) -> acc + { id * i }
    }
  })
}

fn parse(input: String) -> List(Block) {
  input
  |> string.trim
  |> string.to_graphemes
  |> do_parse(True, [], 0)
}

fn do_parse(
  input: List(String),
  next_is_file: Bool,
  acc: List(Block),
  next_id: Int,
) {
  case input {
    [] -> acc
    [curr, ..rest] -> {
      let assert Ok(size) = int.parse(curr)
      let #(block_val, next_id) = case next_is_file {
        False -> #(Empty, next_id)
        True -> #(FileBlock(next_id), next_id + 1)
      }
      let curr_blocks = list.repeat(block_val, size)
      let new_acc = list.append(acc, curr_blocks)
      do_parse(rest, !next_is_file, new_acc, next_id)
    }
  }
}

fn defrag_block(disk: List(Block)) -> List(Block) {
  do_defrag_block(disk, [])
}

fn do_defrag_block(frag_disk: List(Block), acc: List(Block)) -> List(Block) {
  case frag_disk {
    [] -> acc |> list.reverse
    [curr] -> [curr, ..acc] |> list.reverse
    [curr, ..rest] -> {
      case curr {
        FileBlock(_) -> do_defrag_block(rest, [curr, ..acc])
        Empty -> {
          let rev = list.reverse(rest)
          // let without_empty = list.drop_while(rev, fn(it){
          //   case it {
          //     Empty -> True
          //     FileBlock(_) -> False
          //   }
          // })
          // let assert Ok(#(last_fb, rest_rev)) = list.pop(without_empty, fn(_it){True})
          let pop_res =
            list.pop(rev, fn(it) {
              case it {
                Empty -> False
                FileBlock(_) -> True
              }
            })
          let #(last_fb, rest_rev) = case pop_res {
            Error(_) -> #(Empty, [])
            Ok(r) -> r
          }
          //losing final empty space (not important)
          do_defrag_block(rest_rev |> list.reverse, [last_fb, ..acc])
        }
      }
    }
  }
}

fn print_disk(disk: List(Block)) {
  list.fold(disk, "", fn(acc, block) {
    acc
    <> {
      case block {
        Empty -> "."
        FileBlock(id) -> int.to_string(id)
      }
    }
  })
  |> io.println

  disk
}

fn part2(input: String) -> Int {
  let disk = parse2(input)

  let def_disk = defrag_file(disk) |> files_to_blocks()

  list.index_fold(def_disk, 0, fn(acc, block, i) {
    case block {
      Empty -> acc
      FileBlock(id) -> acc + { id * i }
    }
  })
}

type Segment {
  File(id: Int, size: Int)
  EmptySegment(size: Int)
}

fn parse2(input: String) -> List(Segment) {
  input
  |> string.trim
  |> string.to_graphemes
  |> do_parse2(True, [], 0)
}

fn do_parse2(
  input: List(String),
  next_is_file: Bool,
  acc: List(Segment),
  next_id: Int,
) {
  case input {
    [] -> acc |> list.reverse
    [curr, ..rest] -> {
      let assert Ok(size) = int.parse(curr)
      let #(val, next_id) = case next_is_file {
        False -> #(EmptySegment(size), next_id)
        True -> #(File(next_id, size), next_id + 1)
      }
      do_parse2(rest, !next_is_file, [val, ..acc], next_id)
    }
  }
}

fn files_to_blocks(files: List(Segment)) -> List(Block) {
  do_files_to_blocks(files, [])
}

fn do_files_to_blocks(files: List(Segment), acc: List(Block)) -> List(Block) {
  case files {
    [] -> acc
    [curr, ..rest] -> {
      let #(block, times) = case curr {
        EmptySegment(s) -> #(Empty, s)
        File(id, s) -> #(FileBlock(id), s)
      }
      let curr_blocks = list.repeat(block, times)
      do_files_to_blocks(rest, list.append(acc, curr_blocks))
    }
  }
}

fn print_segments(segments: List(Segment)) -> List(Segment) {
  segments |> files_to_blocks |> print_disk

  segments
}

fn defrag_file(files: List(Segment)) -> List(Segment) {
  do_defrag_file(files |> list.reverse, files)
}

fn do_defrag_file(files: List(Segment), acc: List(Segment)) -> List(Segment) {
  // io.debug("iter")
  // print_segments(acc)
  // print_segments(files)
  case files {
    [] -> acc
    [curr, ..rest] ->
      case curr {
        File(_id, _size) -> {
          let n_acc = place_item(acc, curr)
          do_defrag_file(rest, n_acc)
        }
        EmptySegment(_) -> do_defrag_file(rest, acc)
      }
  }
}

fn place_item(state: List(Segment), item: Segment) -> List(Segment) {
  let assert File(item_id, item_size) = item

  let #(pre_place, place_next) =
    list.split_while(state, fn(x) {
      case x {
        EmptySegment(s) if s >= item_size -> False
        File(fid, _s) if fid == item_id -> False
        _ -> True
      }
    })

  //get elements that go after item
  let next = case place_next {
    [] -> []
    [EmptySegment(s), ..rest] -> {
      case s - item_size {
        0 -> rest
        rest_empty -> [EmptySegment(rest_empty), ..rest]
      }
      //remove item from next
      |> list.map(fn(x) {
        case x {
          File(fid, s) if fid == item_id -> EmptySegment(s)
          _ -> x
        }
      })
    }
    //item is in place
    [_, ..rest] -> rest
  }

  list.append(pre_place, [item, ..next])
}
