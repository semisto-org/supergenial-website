# Imports a CODA file: one BankStatement per statement, its movements, and a first automatic reconciliation.
class CodaImport
  Result = Struct.new(:statements, :matched, :skipped, keyword_init: true)

  def initialize(data, filename: nil)
    @data, @filename = data, filename
  end

  def run
    result = Result.new(statements: [], matched: 0, skipped: 0)
    CodaParser.parse(@data).each do |parsed|
      digest = Digest::SHA256.hexdigest([ parsed.iban, parsed.statement_on, parsed.number, parsed.opening_balance, parsed.closing_balance ].join("|"))
      if BankStatement.exists?(digest:)
        result.skipped += 1
        next
      end
      statement = create_statement(parsed, digest)
      result.statements << statement
      result.matched += statement.transactions.count(&:auto_match)
    end
    result
  end

  private
    def create_statement(parsed, digest)
      BankStatement.transaction do
        statement = BankStatement.create!(iban: parsed.iban, number: parsed.number, statement_on: parsed.statement_on, opening_balance: parsed.opening_balance,
                                          closing_balance: parsed.closing_balance || parsed.opening_balance, filename: @filename, digest:, user: Current.user)
        parsed.movements.each do |movement|
          statement.transactions.create!(movement.to_h.slice(:sequence, :booked_on, :value_on, :amount, :bank_reference, :transaction_code,
                                                             :structured_reference, :communication, :counterparty_iban, :counterparty_name)
                                                 .merge(booked_on: movement.booked_on || movement.value_on || parsed.statement_on))
        end
        statement.file.attach(io: StringIO.new(@data), filename: @filename.presence || "extrait-#{parsed.number}.cod", content_type: "text/plain")
        statement
      end
    end
end
