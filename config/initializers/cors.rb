Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'http://localhost:8081', 'http://localhost:3001' # Adicione o endereço do React Native/Android
    resource '*',
      headers: :any,
      methods: [:get, :post, :delete, :put, :patch, :options, :head],
      expose: ['X-API-Key']  
  end
end