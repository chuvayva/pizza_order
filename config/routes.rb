Rails.application.routes.draw do
  resources :orders, only: %i[index update]

  root to: redirect("/orders")
end
