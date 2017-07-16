GdriveCrm::Application.routes.draw do
  devise_for :users

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Example of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Example of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


  match 'feedback/:id/status' => 'feedback#status', :via => :post
  match 'feedback/:id/updateemail' => 'feedback#updateemail', :via => :post
  match 'feedback/reload' => 'feedback#reload', :via => :post
  get 'feedback/list' => 'feedback#list'
  get 'feedback/search' => 'feedback#search'
  get 'feedback/analyse' => 'feedback#analyse'
  match 'feedback' => 'feedback#create', :via => :post
  get 'echo' => 'debug#echo'
  get 'echo/auth' => 'debug#echo_auth'
  get 'echo/message' => 'debug#message'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'feedback#index', :via => [:get, :post]

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
