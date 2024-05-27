type InterpolationStepDefinition {
  InterpolationStepDefinition(value: Float, function: FunctionDefinition)
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
  Avg(Int)
}

type NodeInfo

type ModuleNode {
  ModuleNode(id: Int, info: NodeInfo, update_func: FunctionDefinition)
}

type ModuleDefinition {
  ModuleDefinition(nodes: List(ModuleNode), sub_modules: List(ModuleDefinition))
}
