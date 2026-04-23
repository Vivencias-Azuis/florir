class MessagesController < ApplicationController
  def index
    msgs = Message.where(patient_id: params[:patient_id]).order(created_at: :asc)
    render json: msgs.map { |m| m.slice(:id, :body, :sender_id, :receiver_id, :read_at, :created_at) }
  end

  def create
    msg = Message.new(message_params)
    if msg.save
      render json: msg.slice(:id, :body), status: :created
    else
      render json: { errors: msg.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def read
    msg = Message.find(params[:id])
    msg.update!(read_at: Time.current)
    head :ok
  end

  private

  def message_params
    params.permit(:patient_id, :receiver_id, :body).merge(
      clinic_id: Current.clinic_id,
      sender_id: current_user.id
    )
  end
end
