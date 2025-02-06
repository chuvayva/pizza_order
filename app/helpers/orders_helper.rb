module OrdersHelper
  def render_attribute(model, key)
    "#{model.class.human_attribute_name(key)}: #{model.send(key)}"
  end
end
