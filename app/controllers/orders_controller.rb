class OrdersController < ApplicationController
  before_action :set_order, only: :update

  def index
    @orders = Order.all.order(:created_at).decorate
  end

  def update
    respond_to do |format|
      if @order.update(order_params)
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@order) }
      else
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params.expect(:id))
  end

  def order_params
    params.expect(order: [ :state ])
  end
end
