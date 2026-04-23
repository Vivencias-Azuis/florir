Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3000"),
            /\Ahttps:\/\/.*\.florir\.app\z/
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: [ "Authorization" ]
  end
end
