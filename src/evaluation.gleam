import gleam/list
import gleam/float
import gleam/result.{then}
import gleam/int

type InterpolationStep {
  InterpolationStep(value: Float, function: Function)
}

type Function {
  Value(Float)
  Add(Function, Function)
  Sub(Function, Function)
  Mul(Function, Function)
  Div(Function, Function)
  Pow(Function, Function)
  Interpolate(Float, List(InterpolationStep))
  Avg(List(Float))
}

fn evaluate(function: Function) -> Result(Float, Nil) {
  case function {
    Value(x) -> Ok(x)
    Add(a, b) ->
      case evaluate(a), evaluate(b) {
        Ok(a), Ok(b) -> Ok(a +. b)
        _, _ -> Error(Nil)
      }
    Sub(a, b) ->
      case evaluate(a), evaluate(b) {
        Ok(a), Ok(b) -> Ok(a -. b)
        _, _ -> Error(Nil)
      }
    Mul(a, b) ->
      case evaluate(a), evaluate(b) {
        Ok(a), Ok(b) -> Ok(a *. b)
        _, _ -> Error(Nil)
      }
    Div(a, b) ->
      case evaluate(a), evaluate(b) {
        Ok(a), Ok(b) -> Ok(a /. b)
        _, _ -> Error(Nil)
      }
    Pow(a, b) ->
      case evaluate(a), evaluate(b) {
        Ok(a), Ok(b) -> float.power(a, b)
        _, _ -> Error(Nil)
      }
    Interpolate(value, functions) -> interpolate(value, functions)
    Avg(values) -> Ok(float.sum(values) /. int.to_float(list.length(values)))
  }
}

fn interpolate(
  value: Float,
  interpolation: List(InterpolationStep),
) -> Result(Float, Nil) {
  let sorted =
    list.sort(interpolation, by: fn(a, b) { float.compare(a.value, b.value) })
  use first <- then(case sorted {
    [first, ..] -> Ok(first)
    [] -> Error(Nil)
  })
  use last <- then(list.reduce(sorted, fn(_, b) { b }))

  let #(start, stop) =
    list.fold(over: sorted, from: #(first, last), with: fn(carry, new) {
      let #(start, stop) = carry
      case value >. new.value, new.value <. stop.value && value <. new.value {
        True, _ -> #(new, stop)
        _, True -> #(start, new)
        _, _ -> carry
      }
    })

  let total_diff = case start.value -. stop.value {
    0.0 -> 1.0
    x -> x
  }
  let small_diff = value -. start.value

  case evaluate(start.function), evaluate(stop.function) {
    Ok(start_value), Ok(stop_value) ->
      Ok({ stop_value -. start_value } *. { small_diff /. total_diff })
    _, _ -> Error(Nil)
  }
}
