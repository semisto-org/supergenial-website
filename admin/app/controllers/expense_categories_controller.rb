class ExpenseCategoriesController < ApplicationController
  before_action :set_expense_category, only: %i[ edit update destroy validate ]
  allow_read_only_writes only: :validate

  def index
    @expense_categories = ExpenseCategory.ordered.includes(:comments)
  end

  def new
    @expense_category = ExpenseCategory.new(position: ExpenseCategory.maximum(:position).to_i + 1)
  end

  def create
    @expense_category = ExpenseCategory.new(expense_category_params)
    if @expense_category.save
      redirect_to expense_categories_path, notice: "Catégorie ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense_category.update(expense_category_params)
      redirect_to expense_categories_path, notice: "Catégorie mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @expense_category.destroy
      redirect_to expense_categories_path, notice: "Catégorie supprimée.", status: :see_other
    else
      redirect_to expense_categories_path, alert: @expense_category.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # The accountant confirms (or withdraws) the proposed accounting treatment of a category.
  def validate
    @expense_category.update!(validated_at: @expense_category.validated? ? nil : Time.current)
    redirect_to expense_categories_path
  end

  private
    def set_expense_category
      @expense_category = ExpenseCategory.find(params[:id])
    end

    def expense_category_params
      params.expect(expense_category: %i[ key name pcmn_account vat_rate vat_deductible_percent tax_deductible_percent position notes ])
    end
end
