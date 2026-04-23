class GoalProgressesController < ApplicationController
  def index
    goal = TherapeuticGoal.find(params[:therapeutic_goal_id])
    render json: goal.goal_progresses.order(recorded_at: :asc).map { |p| progress_json(p) }
  end

  def create
    goal = TherapeuticGoal.find(params[:therapeutic_goal_id])
    progress = goal.goal_progresses.new(progress_params)
    if progress.save
      render json: progress_json(progress), status: :created
    else
      render json: { errors: progress.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def progress_params
    params.permit(:session_id, :therapist_id, :score, :notes, :recorded_at)
  end

  def progress_json(p)
    p.slice(:id, :goal_id, :session_id, :therapist_id, :score, :notes, :recorded_at)
  end
end
