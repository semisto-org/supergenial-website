class AdminMcp::Contracts::BillContract < AdminMcp::Tool
  description "Create the draft invoice of a contract's next due date (at the price in force then) and move its next " \
              "billing date forward by one period. Review the draft with get_invoice, then issue it with issue_invoice."
  writes!
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:)
        contract = find(Contract, id)
        invoice = contract.bill!
        { invoice: AdminMcp::Serializer.invoice(invoice, detail: true), contract: AdminMcp::Serializer.contract(contract.reload) }
      end
  end
end
