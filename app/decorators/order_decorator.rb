class OrderDecorator < Draper::Decorator
  delegate_all

  def total_price
    Pricing::Calculator.total_price(object).format
  end

  def created_at
    I18n.l(object.created_at, format: :long)
  end

  def promotion_codes
    object.promotion_codes.join(", ").presence || "-"
  end

  def discount_code
    object.discount_codes.first || "-"
  end

  def order_items
    object.order_items.decorate
  end
end
