# A fictive CODA file for the tests (account, amounts and names are made up).
module CodaFixture
  # Builds a fictive CODA file: each record is placed field by field at its 1-based position.
  def self.record(fields)
    line = " " * 128
    fields.each { |position, value| line[position - 1, value.size] = value }
    line
  end

  def self.amount(value) = format("%015d", (value.abs * 1000).round)

  def self.file
    [
      record(1 => "0", 6 => "011026", 128 => "2"),
      record(1 => "12", 3 => "042", 6 => "BE68539007547034", 40 => "EUR", 43 => "0", 44 => amount(1000), 59 => "011026", 65 => "MARCO & VESPUCCI SRL"),
      # Client payment with a structured communication
      record(1 => "21", 3 => "0001", 7 => "0000", 11 => "REF0000000000000001", 32 => "0", 33 => amount(121), 48 => "021026", 54 => "00150000",
             62 => "1", 63 => "101", 66 => "202600004397", 116 => "021026", 126 => "0", 127 => "1"),
      record(1 => "23", 3 => "0001", 7 => "0000", 11 => "BE71096123456769", 48 => "CLIENT FICTIF SRL"),
      # Supplier payment with a free communication on two records
      record(1 => "21", 3 => "0002", 7 => "0000", 11 => "REF0000000000000002", 32 => "1", 33 => amount(242), 48 => "031026", 54 => "00010000",
             62 => "0", 63 => "Facture 2026-0042", 116 => "031026", 126 => "1", 127 => "1"),
      record(1 => "22", 3 => "0002", 7 => "0000", 11 => " merci"),
      record(1 => "23", 3 => "0002", 7 => "0000", 11 => "BE62510007547061", 48 => "FOURNISSEUR FICTIF"),
      # A globalised detail, not counted
      record(1 => "21", 3 => "0002", 7 => "0001", 11 => "REF0000000000000003", 32 => "1", 33 => amount(242), 116 => "031026"),
      record(1 => "8", 2 => "042", 5 => "BE68539007547034", 42 => "0", 43 => amount(879), 58 => "031026"),
      record(1 => "9", 17 => amount(242), 32 => amount(121))
    ].join("\r\n")
  end
end
