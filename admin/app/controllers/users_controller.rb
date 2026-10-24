# Accounts with access to the admin (Michael, the accountant). Admins only.
class UsersController < ApplicationController
  require_admin
  before_action :set_user, only: %i[ edit update destroy reset_two_factor ]

  def index
    @users = User.order(:role, :email_address)
  end

  def new
    @user = User.new(role: "accountant")
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "Compte créé : #{@user.email_address} activera la double authentification à sa première connexion."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attributes = user_params
    attributes = attributes.except(:password) if attributes[:password].blank?
    attributes = attributes.except(:role) if @user == Current.user
    if @user.update(attributes)
      redirect_to users_path, notice: "Compte mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == Current.user
      redirect_to users_path, alert: "Tu ne peux pas supprimer ton propre compte."
    else
      @user.destroy
      redirect_to users_path, notice: "Compte supprimé.", status: :see_other
    end
  end

  def reset_two_factor
    @user.reset_two_factor!
    redirect_to users_path, notice: "Double authentification réinitialisée : #{@user.email_address} la reconfigurera à sa prochaine connexion."
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[ name email_address role password ])
    end
end
