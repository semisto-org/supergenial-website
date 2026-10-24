# One yearly series YYYY-NNN shared by invoices and credit notes, continuing after the last OkiOki number.
module InvoiceNumbering
  module_function

  def next(year)
    pattern = /\A#{year}-(\d+)\z/
    used = Invoice.where("number LIKE ?", "#{year}-%").pluck(:number).filter_map { |number| number[pattern, 1]&.to_i }
    floor = CompanyProfile.current.last_external_number.to_s[pattern, 1].to_i
    format("%d-%03d", year, [ *used, floor ].max + 1)
  end

  # Belgian structured communication +++123/4567/89012+++ : ten digits from the number, then modulo 97.
  def structured_reference(number)
    year, sequence = number.split("-")
    base = "#{year}#{sequence.to_i.to_s.rjust(6, '0')}"
    check = (base.to_i % 97).then { |rest| rest.zero? ? 97 : rest }
    digits = "#{base}#{check.to_s.rjust(2, '0')}"
    "+++#{digits[0, 3]}/#{digits[3, 4]}/#{digits[7, 5]}+++"
  end

  # The twelve digits read from a bank statement, written the usual way.
  def format_structured(digits)
    digits = digits.to_s.gsub(/\D/, "")
    digits.size == 12 ? "+++#{digits[0, 3]}/#{digits[3, 4]}/#{digits[7, 5]}+++" : digits
  end
end
