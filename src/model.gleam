import definitions.{type FunctionDefinition, type ModuleNode}
import evaluation.{type Function}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result.{then}

pub type ModelNode {
  ModelNode(
    module_node: ModuleNode,
    recommended_value: Float,
    actual_value: Option(Float),
    updated: Bool,
  )
}

pub type Model {
  Model(nodes: Dict(Int, ModelNode), sub_models: List(List(Model)))
}

type FunctionValue {
  Value(Float)
  Array(List(Float))
}

fn model_contains_value(model: Model, id) {
  model.nodes
  |> dict.get(id)
  |> result.is_ok
}

fn get_model_value(model: Model, id) -> Result(#(Model, Float), _) {
  use node <- then(
    model.nodes
    |> dict.get(id),
  )
  case node.actual_value, node.updated {
    Some(value), _ -> Ok(#(model, value))
    _, True -> Ok(#(model, node.recommended_value))
    _, False -> recalculate_value(model, id)
  }
}

fn module_contains_value(module: List(Model), id) {
  module
  |> list.all(fn(m) { model_contains_value(m, id) })
}

fn module_reccursively_contains_value(module: List(Model), id) {
  module
  |> list.all(fn(m) {
    model_contains_value(m, id)
    || {
      list.length(m.sub_models) > 0
      && m.sub_models
      |> list.any(fn(m) { module_reccursively_contains_value(m, id) })
    }
  })
}

fn get_module_values(module: List(Model), id) {
  module
  |> list.fold(Ok(#([], [])), fn(result, model) {
    case result {
      Error(_) -> Error(Nil)
      Ok(#(model_result, value_result)) ->
        case get_model_value(model, id) {
          Error(_) -> Error(Nil)
          Ok(#(model, value)) ->
            Ok(#([model, ..model_result], [value, ..value_result]))
        }
    }
  })
}

fn get_value(model: Model, id) {
  use <- result.lazy_or(
    get_model_value(model, id)
    |> result.map(fn(a) {
      let #(model, value) = a
      #(model, Value(value))
    }),
  )

  model.sub_models
  |> list.fold(Ok(#([], [])), fn(result, ms) {
    use #(modules, values) <- then(result)
    case module_contains_value(ms, id) {
      True ->
        case get_module_values(ms, id) {
          Ok(#(module, vs)) ->
            Ok(#([module, ..modules], list.concat([vs, values])))
          Error(_) -> Error(Nil)
        }
      False -> Ok(#([ms, ..modules], values))
    }
  })
  |> result.map(fn(a) {
    let #(modules, values) = a
    #(Model(..model, sub_models: modules), Array(values))
  })
}

fn insert_variables(
  model: Model,
  id: Int,
  function: FunctionDefinition,
) -> Result(#(Model, Function), _) {
  let binary_insert_variables = fn(a, b, f: fn(Function, Function) -> Function) {
    use #(model, func_a) <- then(insert_variables(model, id, a))
    use #(model, func_b) <- then(insert_variables(model, id, b))
    Ok(#(model, f(func_a, func_b)))
  }

  let insert_value_function = fn(id, f: fn(Float) -> Function) {
    use #(model, input) <- then(get_value(model, id))
    case input {
      Value(v) -> Ok(#(model, f(v)))
      Array(_) -> Error(Nil)
    }
  }

  let insert_array_function = fn(id, f: fn(List(Float)) -> Function) {
    use #(model, input) <- then(get_value(model, id))
    case input {
      Array(vs) -> Ok(#(model, f(vs)))
      Value(_) -> Error(Nil)
    }
  }

  case function {
    definitions.None -> insert_variables(model, id, definitions.Variable(id))
    definitions.Value(v) -> Ok(#(model, evaluation.Value(v)))
    definitions.Variable(id) -> {
      use value <- insert_value_function(id)
      evaluation.Value(value)
    }
    definitions.Add(a, b) -> {
      use a, b <- binary_insert_variables(a, b)
      evaluation.Add(a, b)
    }
    definitions.Sub(a, b) -> {
      use a, b <- binary_insert_variables(a, b)
      evaluation.Sub(a, b)
    }
    definitions.Mul(a, b) -> {
      use a, b <- binary_insert_variables(a, b)
      evaluation.Mul(a, b)
    }
    definitions.Div(a, b) -> {
      use a, b <- binary_insert_variables(a, b)
      evaluation.Div(a, b)
    }
    definitions.Pow(a, b) -> {
      use a, b <- binary_insert_variables(a, b)
      evaluation.Pow(a, b)
    }
    definitions.Avg(id) -> {
      use values <- insert_array_function(id)
      evaluation.Avg(values)
    }
    definitions.Interpolate(id, step_definitions) -> {
      insert_variables_interpolate(model, id, step_definitions)
    }
  }
}

fn insert_variables_interpolate(
  model: Model,
  id,
  step_definitions,
) -> Result(#(Model, Function), _) {
  use #(model, value) <- then(get_value(model, id))
  use value <- then(case value {
    Value(v) -> Ok(v)
    Array(_) -> Error(Nil)
  })

  step_definitions
  |> list.fold(Ok(#(model, [])), fn(acc, step_definition) {
    use #(model, steps) <- then(acc)
    let definitions.InterpolationStepDefinition(thres, function_definition) =
      step_definition
    use #(model, function) <- then(insert_variables(
      model,
      id,
      function_definition,
    ))
    Ok(#(model, [evaluation.InterpolationStep(thres, function), ..steps]))
  })
  |> result.map(fn(res) {
    let #(model, steps) = res
    #(model, evaluation.Interpolate(value, steps))
  })
}

fn recalculate_value(model: Model, id) -> Result(#(Model, Float), _) {
  use node <- then(
    model.nodes
    |> dict.get(id),
  )

  use #(model, func) <- then(insert_variables(
    model,
    id,
    node.module_node.update_func,
  ))

  use recommended_value <- then(evaluation.evaluate(func))
  let node = ModelNode(..node, recommended_value: recommended_value)
  let nodes =
    model.nodes
    |> dict.insert(id, node)
  Ok(#(Model(..model, nodes: nodes), recommended_value))
}

pub fn set_value(model: Model, id, value) -> Result(Model, _) {
  use node <- then(
    model.nodes
    |> dict.get(id),
  )

  let node = ModelNode(..node, actual_value: value)
  let nodes =
    model.nodes
    |> dict.insert(id, node)
  let model = Model(..model, nodes: nodes)
  mark_outdated(model, id)
}

fn mark_outdated_and_get_dependents(
  model: Model,
  id,
) -> Result(#(Model, List(Int)), _) {
  use <- result.lazy_or(
    model.nodes
    |> dict.get(id)
    |> result.map(fn(node) {
      let node = ModelNode(..node, updated: False)
      let nodes =
        model.nodes
        |> dict.insert(id, node)
      let model = Model(..model, nodes: nodes)

      #(model, node.module_node.dependents)
    }),
  )

  use #(sub_models, dependents) <- then(
    model.sub_models
    |> list.fold(Ok(#([], [])), fn(acc, sub_model) {
      use #(sub_models, dependents) <- then(acc)
      case module_reccursively_contains_value(sub_model, id) {
        False -> Ok(#([sub_model, ..sub_models], dependents))
        True -> {
          use #(sub_model, dependents) <- then(
            sub_model
            |> list.fold(Ok(#([], [])), fn(acc, model) {
              use #(models, _) <- then(acc)
              use #(model, dependents) <- then(mark_outdated_and_get_dependents(
                model,
                id,
              ))
              Ok(#([model, ..models], dependents))
            }),
          )
          Ok(#([sub_model, ..sub_models], dependents))
        }
      }
    }),
  )
  Ok(#(Model(..model, sub_models: sub_models), dependents))
}

fn mark_outdated(model: Model, id) -> Result(Model, _) {
  use #(model, dependents) <- then(mark_outdated_and_get_dependents(model, id))
  dependents
  |> list.fold(Ok(model), fn(acc, dependent) {
    use model <- then(acc)
    mark_outdated(model, dependent)
  })
}
