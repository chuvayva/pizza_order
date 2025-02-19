class OrderItemDecorator < Draper::Decorator
  delegate_all

  def name
    "#{object.name} (#{size})"
  end

  def addons_string
    object.addons.join(", ")
  end

  def removals_string
    object.removals.join(", ")
  end
end
