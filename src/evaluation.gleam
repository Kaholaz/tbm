import gleam/float
import gleam/int
import gleam/list
import gleam/result.{then}

pub type InterpolationStep {
  InterpolationStep(value: Float, function: Function)
}

pub type Function {
  Value(Float)
  Add(Function, Function)
  Sub(Function, Function)
  Mul(Function, Function)
  Div(Function, Function)
  Pow(Function, Function)
  Interpolate(Float, List(InterpolationStep))
  Avg(List(Float))
}

fn binary_function_eval(
  a: Function,
  b: Function,
  function: fn(Float, Float) -> Result(Float, _),
) {
  case evaluate(a), evaluate(b) {
    Ok(a), Ok(b) -> function(a, b)
    _, _ -> Error(Nil)
  }
}

pub fn evaluate(function: Function) -> Result(Float, _) {
  case function {
    Value(x) -> Ok(x)
    Add(a, b) -> {
      use a, b <- binary_function_eval(a, b)
      Ok(a -. b)
    }
    Sub(a, b) -> {
      use a, b <- binary_function_eval(a, b)
      Ok(a -. b)
    }
    Mul(a, b) -> {
      use a, b <- binary_function_eval(a, b)
      Ok(a *. b)
    }
    Div(a, b) -> {
      use a, b <- binary_function_eval(a, b)
      Ok(a /. b)
    }
    Pow(a, b) -> {
      use a, b <- binary_function_eval(a, b)
      float.power(a, b)
    }
    Interpolate(value, functions) -> interpolate(value, functions)
    Avg(values) -> Ok(float.sum(values) /. int.to_float(list.length(values)))
  }
}

pub fn interpolate(
  value: Float,
  interpolation: List(InterpolationStep),
) -> Result(Float, _) {
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

  let total_diff = case stop.value -. start.value {
    0.0 -> 1.0
    x -> x
  }
  let small_diff = value -. start.value

  use start_value, stop_value <- binary_function_eval(
    start.function,
    stop.function,
  )
  Ok(
    start_value
    +. { { stop_value -. start_value } *. { small_diff /. total_diff } },
  )
}
