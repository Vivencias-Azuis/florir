class PatientsController < ApplicationController
  before_action :set_patient, only: %i[show update destroy]

  def index
    render json: Patient.all.map { |p| patient_json(p) }
  end

  def show
    render json: patient_json(@patient)
  end

  def create
    patient = Patient.new(patient_params)
    patient.clinic_id = Current.clinic_id
    if patient.save
      render json: patient_json(patient), status: :created
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @patient.update(patient_params)
      render json: patient_json(@patient)
    else
      render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @patient.destroy
    head :no_content
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def patient_params
    params.permit(:name, :birth_date, :diagnosis_date, :diagnosis_level,
                  :communication_method, :notes)
  end

  def patient_json(p)
    p.slice(:id, :name, :birth_date, :diagnosis_date, :diagnosis_level,
            :communication_method, :notes, :created_at)
  end
end
