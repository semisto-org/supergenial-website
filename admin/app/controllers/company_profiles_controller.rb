class CompanyProfilesController < ApplicationController
  before_action :set_company_profile

  def show
  end

  def edit
  end

  def update
    if @company_profile.update(company_profile_params)
      redirect_to company_profile_path, notice: "Société mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_company_profile
      @company_profile = CompanyProfile.current
    end

    def company_profile_params
      params.expect(company_profile: %i[ legal_name trade_name vat_number street postal_code city country email phone website
                                         iban bic payment_terms_days last_external_number vat_tracked_since invoice_footer ])
    end
end
