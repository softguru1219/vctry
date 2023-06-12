Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: 'home#index'
  devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations', passwords: 'users/passwords', confirmations: 'users/confirmations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_scope :user do
    # get '/users', to: 'users/registrations#new'
    # get 'users/profile', :to => 'users/registrations#edit', :as => :edit_profile
    get '/users/sign_out', to: 'devise/sessions#destroy'
  end

  resources :users, :only => [:index, :show, :destroy]
  resources :tournaments, :only => [:show]
  resources :raffles, :only => [:index, :show]
  
  resource :users do
    post '/subscribe', action: :subscribe, as: :subscribe
    post '/renew_cancel', action: :renew_cancel, as: :renew_cancel
    post '/raffle_ticket', action: :raffle_ticket, as: :raffle_ticket

    get ':id/photo/upload' => 'users#photo_upload', as: :photo_upload
    post '/transaction/buyin', action: :transaction_buyIn, as: :transaction_buyin
    post '/transaction/refund', action: :transaction_refund, as: :transaction_refund
    get '/:id/friends', action: :friends, as: :friends
    get '/:id/friend_search', action: :friend_search, as: :friend_search
    get '/:id/add_friend', action: :add_friend, as: :add_friend
    get '/:id/confirm_friend', action: :confirm_friend, as: :confirm_friend
    get '/:id/remove_friend', action: :remove_friend, as: :remove_friend
    post '/transaction/vourcher', action: :transaction_vourcher, as: :transaction_vourcher
    post '/:id/promotion', action: :promotion, as: :promotion
    post '/:id/active_creator', action: :active_creator, as: :active_creator
    get '/:id/notifications', action: :notifications, as: :notifications
    get '/:id/delete_notification', action: :delete_notification, as: :delete_notification
  end
  
  get '/content_creator' => 'home#creator_page', as: :content_creator
  post '/active_creator' => 'home#active_creator', as: :active_creator
  post '/partner_request' => 'home#partner_request', as: :partner_request
  
  get '/tournaments(?game=:filter)' => 'tournaments#index', as: :tournaments
  get '/filtered_tournaments' => 'tournaments#filtered_tournaments', as: :filtered_tournaments
  get '/tournaments/41' => 'tournaments#tournaments_41', as: :tournaments_41
  get '/tournaments/47' => 'tournaments#tournaments_41', as: :tournaments_47
  get '/tournaments/:id/join' => 'tournaments#join_tournament', as: :tournament_join
  get '/tournaments/:id/register' => 'tournaments#tournament_register', as: :tournament_register
  get '/tournaments/:id/cancel' => 'tournaments#tournament_cancel', as: :tournament_cancel
  get '/tournaments/:id/checkin' => 'tournaments#tournament_checkin', as: :tournament_checkin

  get '/tournaments/:id/match/:match_id' => 'tournaments#tournament_round', as: :tournament_round
  get '/tournaments/:id/match_check/:match_id' => 'tournaments#tournament_match_check', as: :tournament_match_check
  post '/tournaments/:id/match_update_status/:match_id' => 'tournaments#match_update_status', as: :tournament_update_status
  get '/tournaments/:id/completed_match/:match_id' => 'tournaments#tournament_completed_match', as: :tournament_completed_match
  get '/tournaments/:id/complete' => 'tournaments#tournament_final', as: :tournament_final
  get '/tournaments/:id/standing' => 'tournaments#standing', as: :tournament_standing

  post '/tournament/:id/submit_score/:match_id' => 'tournaments#submit_score', as: :submit_score
  post '/tournament/:id/confirm_score/:match_id' => 'tournaments#confirm_score', as: :confirm_score
  post '/refresh_tournament' => 'tournaments#refresh_tournament', as: :refresh_tournament
  post '/save_stage' => 'tournaments#save_stage', as: :save_stage

  get "/get_premium", controller: "premium", action: "index", as: :get_premium
  
  # get '/notifications' => 'users#notifications', as: :notifications
  get '/past_raffles' => 'raffles#past_raffles', as: :past_raffles
  post '/get_raffles' => 'raffles#get_raffles', as: :get_raffles
  post '/update_chances' => 'raffles#update_chances', as: :update_chances
  post '/generate_winners' => 'raffles#generate_winners', as: :generate_winners
  
  get '/legalnotice' => 'home#legal_notice', as: :legal_notice
  get '/privacy' => 'home#privacy', as: :privacy
  get '/terms' => 'home#terms', as: :terms

  get '/impressum' => 'home#impressum', as: :impressum
  get '/datenschutz' => 'home#datenschutz', as: :datenschutz
  get '/AGB' => 'home#agb', as: :agb

  get '/faq' => 'home#faq', as: :faq
  get '/about' => 'home#about', as: :about
  get '/jobs' => 'home#jobs', as: :jobs
  get '/Arbeitsplätze' => 'home#arb', as: :arb
  get '/Über' => 'home#uber', as: :uber

  resources :groups, :only => [:index]

  resources :calendars, :only => [:index]
  resource :calendars do
    post '/get_tournament', action: :get_tournaments, as: :get_tournaments
  end

  resources :wallets, :only => [:index]
  resource :wallets do
    post '/transaction', action: :transaction, as: :transaction
  end

  get '/vctry-pack-race-event' => 'race_event#index', as: :race_events

  match '/webhooks/:integrate_name' => 'webhooks#receive', as: :receive_webhooks, via: [:post, :head]
end
