class AdminMcp::Plans::DeletePlan < AdminMcp::DeleteTool
  description "Delete a plan and its prices. Refused while contracts use it: set active to false instead."
  model Plan
end
