class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = TokenService.decode(token)
    render json: { error: "Unauthorized" }, status: :unauthorized and return unless payload

    Current.clinic_id = payload[:clinic_id]
    Current.user = User.find_by(id: payload[:user_id])
    render json: { error: "Unauthorized" }, status: :unauthorized unless Current.user
  end

  def current_user
    Current.user
  end
end
