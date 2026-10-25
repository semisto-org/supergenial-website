class AdminMcp::Invoices::DeleteInvoice < AdminMcp::DeleteTool
  description "Delete a draft invoice (issued documents cannot be deleted: use create_credit_note). " \
              "Its time entries go back to a_facturer."
  model Invoice
end
