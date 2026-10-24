class AdminMcp::Contracts::DeleteContract < AdminMcp::DeleteTool
  description "Delete a contract. Invoices already recorded for it are kept. To stop a contract, prefer status termine."
  model Contract
end
