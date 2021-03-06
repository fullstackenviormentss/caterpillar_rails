Rails.application.routes.draw do
  get '/', to: redirect('home.html')

  post 'bot' => 'bot#bot'
  post 'query' => 'bot#text'

  namespace :api do
    namespace :v1 do
      post 'get_info' => 'query#get_info'
    end
  end
end
