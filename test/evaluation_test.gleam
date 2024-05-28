import evaluation.{Interpolate, InterpolationStep, Value, evaluate}
import gleeunit/should

pub fn interpolate_over_bounds_test() -> Nil {
  let steps = [
    InterpolationStep(2.0, Value(1.0)),
    InterpolationStep(4.0, Value(2.0)),
  ]

  evaluate(Interpolate(5.0, steps))
  |> should.equal(Ok(2.0))

  Nil
}

pub fn interpolate_under_bounds_test() -> Nil {
  let steps = [
    InterpolationStep(2.0, Value(1.0)),
    InterpolationStep(4.0, Value(2.0)),
  ]

  evaluate(Interpolate(1.0, steps))
  |> should.equal(Ok(1.0))

  Nil
}

pub fn interpolate_middle_of_bounds_test() -> Nil {
  let steps = [
    InterpolationStep(2.0, Value(1.0)),
    InterpolationStep(4.0, Value(2.0)),
  ]

  evaluate(Interpolate(3.0, steps))
  |> should.equal(Ok(1.5))

  Nil
}
