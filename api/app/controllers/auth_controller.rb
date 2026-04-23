class AuthController < ApplicationController
  skip_before_action :authenticate!, only: %i[login register]

  def login
    clinic = Clinic.find_by(slug: params[:clinic_slug])
    user = User.unscoped.find_by(email: params[:email], clinic_id: clinic&.id)

    if user&.authenticate(params[:password])
      token = TokenService.encode(user_id: user.id, clinic_id: clinic.id, role: user.role)
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def register
    clinic = Clinic.new(params.require(:clinic).permit(:name, :slug, :email, :phone))
    user_params = params.require(:user).permit(:name, :email, :password)

    ActiveRecord::Base.transaction do
      clinic.save!
      user = User.new(user_params.merge(role: "admin", clinic: clinic))
      user.save!
      token = TokenService.encode(user_id: user.id, clinic_id: clinic.id, role: "admin")
      render json: { token: token, user: user_json(user) }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def user_json(user)
    { id: user.id, name: user.name, email: user.email, role: user.role }
  end
end
