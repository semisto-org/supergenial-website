class AdminMcp::Clients::DeleteClient < AdminMcp::DeleteTool
  description "Delete a client with its contacts, projects, time entries, contracts and packs. " \
              "Refused when the client has invoices: set its status to \"ancien\" instead."
  model Client
end
