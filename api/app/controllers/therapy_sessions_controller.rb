class TherapySessionsController < ApplicationController
  before_action :set_session, only: %i[show update destroy]

  def index
    sessions = if params[:patient_id]
      Patient.find(params[:patient_id]).therapy_sessions.order(scheduled_at: :asc)
    else
      TherapySession.all.order(scheduled_at: :asc)
    end
    render json: sessions.map { |s| session_json(s) }
  end

  def show
    render json: session_json(@session)
  end

  def create
    session = TherapySession.new(session_params)
    session.clinic_id = Current.clinic_id
    if session.save
      render json: session_json(session), status: :created
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @session.update(session_params)
      render json: session_json(@session)
    else
      render json: { errors: @session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @session.destroy
    head :no_content
  end

  private

  def set_session
    @session = TherapySession.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def session_params
    params.permit(:patient_id, :therapist_id, :scheduled_at, :duration_minutes,
                  :status, :modality, :session_notes)
  end

  def session_json(s)
    s.slice(:id, :patient_id, :therapist_id, :scheduled_at, :duration_minutes,
            :status, :modality, :session_notes)
  end
end
