require "test_helper"

class CodaParserTest < ActiveSupport::TestCase
  test "reads statements, balances and movements" do
    statement = CodaParser.parse(CodaFixture.file).sole
    assert_equal [ "BE68539007547034", 42, Date.new(2026, 10, 1), 1000, 879 ],
                 [ statement.iban, statement.number, statement.statement_on, statement.opening_balance, statement.closing_balance ]

    payment, expense = statement.movements
    assert_equal 2, statement.movements.size, "the globalised detail is left out"
    assert_equal [ 121, "202600004397", "BE71096123456769", "CLIENT FICTIF SRL", Date.new(2026, 10, 2) ],
                 [ payment.amount, payment.structured_reference, payment.counterparty_iban, payment.counterparty_name, payment.booked_on ]
    assert_equal [ -242, "Facture 2026-0042 merci", "FOURNISSEUR FICTIF" ], [ expense.amount, expense.communication, expense.counterparty_name ]
  end

  test "Latin-1 files are converted" do
    data = CodaFixture.file.sub("FOURNISSEUR FICTIF", "CAFÉ FICTIF      ").encode(Encoding::ISO_8859_1).force_encoding(Encoding::BINARY)
    assert_equal "CAFÉ FICTIF", CodaParser.parse(data).sole.movements.last.counterparty_name
  end

  test "refuses other files" do
    assert_raises(CodaParser::Error) { CodaParser.parse("Date;Montant\n") }
  end
end
