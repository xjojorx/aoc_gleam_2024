import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import reader

pub fn main() {
  // let input_text = reader.read_input("day05_ex")
  // let input_text = reader.read_input("day05_ex2")
  let input_text = reader.read_input("day05")

  let res = part1(input_text)
  io.println("Part 1: " <> string.inspect(res))
  let res = part2(input_text)
  io.println("Part 2: " <> string.inspect(res))
}

fn part1(input: String) -> Int {
  let #(ordering, page_lists) = parse(input)

  let r =
    page_lists
    |> list.filter(is_ordered(_, ordering))
    |> list.map(fn(page_list) {
      let assert Ok(mid) =
        page_list
        |> list.drop(list.length(page_list) / 2)
        |> list.first

      mid
    })

  int.sum(r)
}

fn part2(input: String) -> Int {
  let #(ordering, page_lists) = parse(input)

  let r =
    page_lists
    |> list.filter(fn(x) { !is_ordered(x, ordering) })
    |> list.map(fn(page_list) {
      let assert Ok(mid) =
        page_list
        |> list.sort(fn(it1, it2) { compare_pages(it1, it2, ordering) })
        |> list.drop(list.length(page_list) / 2)
        |> list.first

      mid
    })

  int.sum(r)
}

fn compare_pages(page1: Int, page2: Int, ordering: OrderingRules) -> order.Order {
  let after1 = dict.get(ordering, page1) |> result.unwrap([])
  case list.contains(after1, page2) {
    True -> order.Gt
    False -> {
      let after2 = dict.get(ordering, page2) |> result.unwrap([])
      case list.contains(after2, page1) {
        True -> order.Lt
        False -> order.Eq
      }
    }
  }
}

fn is_ordered(page_list: List(Int), ordering: OrderingRules) -> Bool {
  do_is_ordered(page_list, ordering, [])
}

fn do_is_ordered(page_list: List(Int), ordering: OrderingRules, seen: List(Int)) {
  case page_list {
    [] -> True
    [page, ..rest] ->
      case dict.get(ordering, page) {
        Error(_) -> do_is_ordered(rest, ordering, [page, ..seen])
        Ok(later) ->
          case list.any(seen, fn(it) { list.contains(later, it) }) {
            True -> False
            False -> do_is_ordered(rest, ordering, [page, ..seen])
          }
      }
  }
}

type OrderingRules =
  Dict(Int, List(Int))

fn parse(input: String) -> #(OrderingRules, List(List(Int))) {
  let #(rules, page_lists) =
    string.split(input, "\n")
    |> list.map(string.trim)
    |> list.split_while(fn(line) { !string.is_empty(line) })

  let ordering: OrderingRules =
    list.fold(rules, dict.new(), fn(acc, curr) {
      let assert [n1, n2] =
        curr
        |> string.split("|")
        |> list.map(fn(part) {
          let assert Ok(n) = int.parse(part)
          n
        })

      dict.upsert(acc, n1, fn(found) {
        case found {
          Some(vals) -> [n2, ..vals]
          None -> [n2]
        }
      })
    })

  let pages: List(List(Int)) =
    page_lists
    |> list.filter(fn(l) { !string.is_empty(l) })
    //drop the empty line
    |> list.map(fn(line) {
      let assert Ok(nums) =
        string.split(line, ",")
        |> list.map(fn(n) { int.parse(n) })
        |> result.all

      nums
    })

  #(ordering, pages)
}
