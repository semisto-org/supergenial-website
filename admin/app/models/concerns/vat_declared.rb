# Documents declared in a closed VAT quarter keep the amounts that were declared.
module VatDeclared
  extend ActiveSupport::Concern

  DECLARED_ATTRIBUTES = %w[ kind issued_on amount vat_amount vat_regime vat_rate base_grid vat_deductible_percent exchange_rate ].freeze

  included do
    belongs_to :vat_period, optional: true
    validate :declared_amounts_are_frozen
    before_destroy :forbid_destroying_declared, prepend: true
  end

  def vat_declared? = vat_period_id_in_database.present?

  private
    def declared_amounts_are_frozen
      return unless vat_declared?
      changed = changed_attribute_names_to_save & DECLARED_ATTRIBUTES
      errors.add(:base, "déclarée dans la TVA #{vat_period.to_quarter.label} : corrige-la par une note de crédit ou une régularisation") if changed.any?
    end

    def forbid_destroying_declared
      return unless vat_declared?
      errors.add(:base, "déclarée dans la TVA #{vat_period.to_quarter.label}, elle ne peut plus être supprimée")
      throw :abort
    end
end
