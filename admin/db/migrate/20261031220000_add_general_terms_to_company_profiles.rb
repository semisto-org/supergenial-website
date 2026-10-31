class AddGeneralTermsToCompanyProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :company_profiles, :general_terms, :text
  end
end
