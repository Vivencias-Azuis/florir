class WidgetsController < ApplicationController
  def index
    widgets = Widget.recent
    render json: widgets.map { |widget| WidgetSerializer.new(widget).as_json }
  end

  def show
    widget = Widget.find(params[:id])
    render json: WidgetSerializer.new(widget).as_json
  end

  def create
    widget = Widget.new(widget_params)

    if widget.save
      render json: WidgetSerializer.new(widget).as_json, status: :created
    else
      render json: { errors: widget.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def widget_params
    params.require(:widget).permit(:name, :description)
  end
end
