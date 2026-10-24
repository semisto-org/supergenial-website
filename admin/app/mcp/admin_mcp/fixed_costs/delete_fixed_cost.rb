class AdminMcp::FixedCosts::DeleteFixedCost < AdminMcp::DeleteTool
  description "Delete a fixed cost. Contracts linked to it are kept and detached. To stop a cost, prefer active false."
  model FixedCost
end
