class AdminMcp::Projects::DeleteProject < AdminMcp::DeleteTool
  description "Delete a project. Its time entries, contracts and invoices are kept and simply detached from it."
  model Project
end
