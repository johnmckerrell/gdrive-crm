Rails.application.routes.draw do
  devise_for :users
  match 'feedback/:id/status' => 'feedback#status', :via => :post
  match 'feedback/:id/updateemail' => 'feedback#updateemail', :via => :post
  match 'feedback/reload' => 'feedback#reload', :via => :post
  match 'feedback/list' => 'feedback#list', :via => [ :get, :post ]
  match 'feedback/search' => 'feedback#search', :via => [ :get, :post ]
  get 'feedback/analyse' => 'feedback#analyse'
  match 'feedback' => 'feedback#create', :via => :post
  match 'echo' => 'debug#echo', :via => [ :get, :post ]
  match 'echo/auth' => 'debug#echo_auth', :via => [ :get, :post ]
  match 'echo/message' => 'debug#message', :via => [ :get, :post ]

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'feedback#index', :via => [:get, :post]
 
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
