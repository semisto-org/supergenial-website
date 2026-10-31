# A PSD2 consent given at the bank through Enable Banking: it lets the admin read the movements of the
# company accounts every day, instead of importing CODA files. The bank limits a consent (180 days at most):
# it then has to be renewed by the account holder.
class BankConnection < ApplicationRecord
  include Choices

  DEFAULT_BANK = "Belfius"
  FIRST_SYNC_DAYS = 89
  OVERLAP_DAYS = 10
  RENEWAL_NOTICE = 14.days

  choices :status, pending: "En attente de la banque", active: "Active", expired: "Expirée"
  choices :psu_type, business: "Compte professionnel", personal: "Accès personnel du gérant"

  belongs_to :user, optional: true, default: -> { Current.user }
  has_many :bank_transactions, dependent: :nullify

  validates :aspsp_name, :country, presence: true

  before_validation { self.state ||= SecureRandom.urlsafe_base64(24) }

  scope :recent, -> { order(created_at: :desc) }

  # Consents lapsing within two weeks, or lapsed, for banks not reconnected since.
  def self.to_renew(now = Time.current)
    renewed = active.where(valid_until: (now + RENEWAL_NOTICE)..).pluck(:aspsp_name)
    where(status: %w[ active expired ]).where(valid_until: ..now + RENEWAL_NOTICE).recent.reject { |connection| connection.aspsp_name.in?(renewed) }.uniq(&:aspsp_name)
  end

  def ibans = accounts.filter_map { |account| account["iban"] }

  def expired?(now = Time.current) = super() || (valid_until.present? && valid_until <= now)

  def to_s = "#{aspsp_name} (#{ibans.join(', ').presence || country})"

  # Stores the session opened by the callback of the bank.
  def activate!(session)
    update!(status: "active", session_id: session.fetch("session_id"), last_error: nil,
            valid_until: session.dig("access", "valid_until")&.then { |value| Time.zone.parse(value) } || valid_until,
            accounts: session.fetch("accounts", []).map do |account|
              { "uid" => account["uid"], "iban" => account.dig("account_id", "iban")&.delete(" "), "name" => account["name"], "currency" => account["currency"] }
            end)
  end

  # Fetches the new booked movements of every account and reconciles them. Returns how many were added.
  def sync!(client: EnableBanking::Client.new, today: Date.current)
    if expired?
      update!(status: "expired")
      return 0
    end
    date_from = last_synced_at ? last_synced_at.to_date - OVERLAP_DAYS : today - FIRST_SYNC_DAYS
    added = accounts.sum do |account|
      client.transactions(account.fetch("uid"), date_from:).count { |transaction| import(account, transaction) }
    end
    update!(last_synced_at: Time.current, last_error: nil)
    added
  rescue EnableBanking::Error => error
    update!(last_error: error.message)
    raise
  end

  private
    # Creates the movement unless it is known already (same id, or the same movement read from a CODA file).
    def import(account, data)
      iban = account["iban"]
      amount = data.dig("transaction_amount", "amount").to_d.abs * (data["credit_debit_indicator"] == "DBIT" ? -1 : 1)
      booked_on = Date.parse(data["booking_date"] || data["value_date"] || data["transaction_date"])
      communication = Array(data["remittance_information"]).join(" ").squish.presence
      external_id = data["entry_reference"].presence || data["transaction_id"].presence ||
                    Digest::SHA256.hexdigest([ iban, booked_on, amount, communication, data["reference_number"] ].join("|"))[0, 32]
      return false if BankTransaction.exists?(account_iban: iban, external_id:)
      return false if iban && BankTransaction.joins(:bank_statement).exists?(bank_statements: { iban: }, booked_on:, amount:)

      counterparty, counterparty_account = amount.negative? ? %w[ creditor creditor_account ] : %w[ debtor debtor_account ]
      transaction = bank_transactions.create!(
        account_iban: iban, external_id:, booked_on:, value_on: data["value_date"]&.then { |value| Date.parse(value) }, amount:,
        counterparty_name: data.dig(counterparty, "name"), counterparty_iban: data.dig(counterparty_account, "iban")&.delete(" "),
        communication:, structured_reference: structured_reference(data["reference_number"], communication),
        bank_reference: data["transaction_id"] || data["entry_reference"]
      )
      transaction.auto_match
      true
    end

    # Belgian structured communication (+++123/4567/89012+++), kept as its twelve digits like CODA does.
    def structured_reference(*texts)
      texts.compact.each do |text|
        digits = text[%r{\+{3}\s*(\d{3})\s*/\s*(\d{4})\s*/\s*(\d{5})\s*\+{3}}] ? $~.captures.join : text.gsub(/\D/, "")
        return digits if digits.size == 12 && valid_check?(digits)
      end
      nil
    end

    def valid_check?(digits) = (digits[0, 10].to_i % 97).then { |rest| rest.zero? ? 97 : rest } == digits[10, 2].to_i
end
