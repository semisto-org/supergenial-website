# Parses a CODA file (Belgian bank statements, Febelfin standard version 2: lines of 128 characters).
# Returns one Statement per statement in the file, with its movements. Only the main movement records
# (detail number 0000) are kept, so that globalised movements and their details are not counted twice.
class CodaParser
  class Error < StandardError; end

  Statement = Struct.new(:iban, :number, :statement_on, :opening_balance, :closing_balance, :holder, :movements, keyword_init: true)
  Movement = Struct.new(:sequence, :booked_on, :value_on, :amount, :bank_reference, :transaction_code, :structured_reference,
                        :communication, :counterparty_iban, :counterparty_name, keyword_init: true)

  def self.parse(data) = new(data).statements

  def initialize(data)
    text = data.dup.force_encoding(Encoding::UTF_8)
    text = data.dup.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8) unless text.valid_encoding?
    @lines = text.delete_prefix("﻿").lines.map { |line| line.chomp.ljust(128) }.reject { |line| line.strip.empty? }
  end

  def statements
    raise Error, "Ce n'est pas un fichier CODA (il doit commencer par un enregistrement 0)." unless @lines.first&.start_with?("0")

    statements, current, movement = [], nil, nil
    @lines.each do |line|
      case line[0]
      when "1"
        current = Statement.new(iban: account(line[1], line[5, 37]), number: line[2, 3].to_i, opening_balance: balance(line[42], line[43, 15]),
                                statement_on: date(line[58, 6]), holder: line[64, 26].strip, movements: [])
        statements << current
      when "2" then movement = movement_record(current, movement, line)
      when "3" then information_record(movement, line)
      when "8"
        raise Error, "Enregistrement 8 sans relevé" unless current
        current.closing_balance = balance(line[41], line[42, 15])
        current.number = line[1, 3].to_i if current.number.zero?
      end
    end
    statements.each { |statement| statement.movements.each { |entry| entry.communication = entry.communication.to_s.squeeze(" ").strip.presence } }
  end

  private
    def movement_record(statement, movement, line)
      raise Error, "Mouvement sans relevé (enregistrement 1 manquant)" unless statement
      detail = line[6, 4]
      case line[1]
      when "1"
        return nil unless detail == "0000"
        structured = line[61] == "1" && line[62, 3] == "101" ? line[65, 12] : nil
        movement = Movement.new(sequence: line[2, 4].to_i, bank_reference: line[10, 21].strip, amount: balance(line[31], line[32, 15]),
                                value_on: date(line[47, 6]), transaction_code: line[53, 8], booked_on: date(line[115, 6]),
                                structured_reference: structured, communication: structured ? nil : line[62, 53])
        statement.movements << movement
        movement
      when "2"
        movement&.communication = "#{movement.communication}#{line[10, 53]}" unless movement&.structured_reference
        movement
      when "3"
        if movement
          movement.counterparty_iban = line[10, 34].strip.presence&.delete(" ")
          movement.counterparty_name = line[47, 35].strip.presence
          movement.communication = "#{movement.communication}#{line[82, 43]}" unless movement.structured_reference
        end
        movement
      else movement
      end
    end

    # Information records (3.x) may continue the communication of the movement they belong to.
    def information_record(movement, line)
      return unless movement && line[6, 4] == "0000" && movement.structured_reference.nil?
      text = case line[1]
      when "1" then line[40, 73]
      when "2" then line[10, 105]
      when "3" then line[10, 90]
      end
      movement.communication = "#{movement.communication} #{text}" if text
    end

    # Account structure 2 = Belgian IBAN, 3 = foreign IBAN; 0 and 1 are old formats.
    def account(structure, field)
      case structure
      when "2" then field[0, 16].strip
      when "3" then field[0, 34].strip
      else field[0, 12].strip
      end
    end

    def balance(sign, digits)
      value = digits.to_d / 1000
      sign == "1" ? -value : value
    end

    def date(value)
      Date.strptime(value, "%d%m%y")
    rescue Date::Error
      nil
    end
end
