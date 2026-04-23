class TherapeuticGoalsController < ApplicationController
  before_action :set_goal, only: %i[show update destroy]

  def index
    goals = Patient.find(params[:patient_id]).therapeutic_goals.order(created_at: :desc)
    render json: goals.map { |g| goal_json(g) }
  end

  def show
    render json: goal_json(@goal)
  end

  def create
    goal = TherapeuticGoal.new(goal_params)
    goal.clinic_id = Current.clinic_id
    if goal.save
      render json: goal_json(goal), status: :created
    else
      render json: { errors: goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @goal.update(goal_params)
      render json: goal_json(@goal)
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    head :no_content
  end

  private

  def set_goal
    @goal = TherapeuticGoal.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def goal_params
    params.permit(:patient_id, :domain, :method, :title, :description,
                  :target, :status, :started_at, :achieved_at)
  end

  def goal_json(g)
    g.slice(:id, :patient_id, :domain, :method, :title, :description,
            :target, :status, :started_at, :achieved_at)
  end
end
