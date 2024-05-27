import gleam/option.{type Option}
import gleam/result.{then}
import gleam/float.{power}
import gleam/list.{sort}
import gleam/int

type FuncInput {
  InputValue(Float)
  InputArray(List(Float))
}

type InterpolationStepDefinition {
  InterpolationStep(value: Float, function: FunctionDefinition)
}

type FunctionDefinition {
  None
  Value(Float)
  Variable(Int)
  Add(FunctionDefinition, FunctionDefinition)
  Sub(FunctionDefinition, FunctionDefinition)
  Mul(FunctionDefinition, FunctionDefinition)
  Div(FunctionDefinition, FunctionDefinition)
  Pow(FunctionDefinition, FunctionDefinition)
  Interpolate(Int, List(InterpolationStepDefinition))
  Avg(List(Float))
}

type NodeInfo

type ModuleNode {
  ModuleNode(id: Int, info: NodeInfo, update_func: FunctionDefinition)
}

type Module {
  Module(nodes: List(ModuleNode), sub_modules: List(Module))
}
