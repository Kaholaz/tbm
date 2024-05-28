pub type InterpolationStepDefinition {
  InterpolationStepDefinition(value: Float, function: FunctionDefinition)
}

pub type FunctionDefinition {
  None
  Value(Float)
  Variable(Int)
  Add(FunctionDefinition, FunctionDefinition)
  Sub(FunctionDefinition, FunctionDefinition)
  Mul(FunctionDefinition, FunctionDefinition)
  Div(FunctionDefinition, FunctionDefinition)
  Pow(FunctionDefinition, FunctionDefinition)
  Interpolate(variable: Int, List(InterpolationStepDefinition))
  Avg(variable: Int)
}

pub type NodeInfo

pub type ModuleNode {
  ModuleNode(
    id: Int,
    dependents: List(Int),
    info: NodeInfo,
    update_func: FunctionDefinition,
  )
}

pub type ModuleDefinition {
  ModuleDefinition(nodes: List(ModuleNode), sub_modules: List(ModuleDefinition))
}
