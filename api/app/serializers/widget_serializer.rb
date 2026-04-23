class WidgetSerializer
  def initialize(widget)
    @widget = widget
  end

  def as_json(*)
    {
      id: @widget.id,
      name: @widget.name,
      description: @widget.description
    }
  end
end
