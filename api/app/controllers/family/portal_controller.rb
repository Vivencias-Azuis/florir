module Family
  class PortalController < ApplicationController
    skip_before_action :authenticate!
    before_action :set_access

    def dashboard
      render json: {
        patient: patient_json(@patient),
        goals: @patient.therapeutic_goals.where(status: "active").map { |g| goal_summary(g) },
        next_session: next_session_json
      }
    end

    def sessions
      sessions = @patient.therapy_sessions
                         .where(scheduled_at: Time.current..)
                         .order(scheduled_at: :asc)
                         .limit(10)
      render json: sessions.map { |s| { id: s.id, scheduled_at: s.scheduled_at,
                                         duration_minutes: s.duration_minutes,
                                         status: s.status, modality: s.modality } }
    end

    def goals
      render json: @patient.therapeutic_goals.where(status: "active").map { |g| goal_summary(g) }
    end

    def messages
      msgs = Message.where(patient_id: @patient.id).order(created_at: :asc)
      render json: msgs.map { |m| { id: m.id, body: m.body, sender_id: m.sender_id,
                                     read_at: m.read_at, created_at: m.created_at } }
    end

    def create_message
      msg = Message.new(
        clinic_id: @patient.clinic_id,
        patient_id: @patient.id,
        sender_id: @access.user_id,
        receiver_id: params[:receiver_id],
        body: params[:body]
      )
      if msg.save
        render json: { id: msg.id, body: msg.body }, status: :created
      else
        render json: { errors: msg.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_access
      @access = FamilyAccess.find_by(access_token: params[:token], active: true)
      render json: { error: "Not found" }, status: :not_found and return unless @access

      @patient = @access.patient
      Current.clinic_id = @patient.clinic_id
    end

    def patient_json(p)
      p.slice(:id, :name, :birth_date, :diagnosis_level, :communication_method)
    end

    def goal_summary(g)
      last = g.goal_progresses.order(recorded_at: :desc).first
      g.slice(:id, :title, :domain, :method, :status).merge(last_score: last&.score)
    end

    def next_session_json
      s = @patient.therapy_sessions.where(scheduled_at: Time.current..)
                  .order(scheduled_at: :asc).first
      return nil unless s

      { scheduled_at: s.scheduled_at, modality: s.modality, status: s.status }
    end
  end
end
