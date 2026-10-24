class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[ show edit update destroy ]

  def index
    @suppliers = Supplier.alphabetical.includes(:expense_category, :fixed_costs)
    @suppliers = @suppliers.select { |supplier| supplier.zone == params[:zone] } if params[:zone].present?
  end

  def show
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to @supplier, notice: "Fournisseur ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: "Fournisseur mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.destroy
    redirect_to suppliers_path, notice: "Fournisseur supprimé.", status: :see_other
  end

  private
    def set_supplier
      @supplier = Supplier.find(params[:id])
    end

    def supplier_params
      params.expect(supplier: %i[ name vat_number iban billing_country group_country expense_category_id peppol_id
                                  require_peppol active website alternative_note notes ])
    end
end
