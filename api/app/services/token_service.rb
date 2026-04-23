class TokenService
  SECRET = ENV.fetch("JWT_SECRET", "dev-secret-change-in-production")
  EXPIRY = 24.hours

  def self.encode(payload)
    payload[:exp] = EXPIRY.from_now.to_i
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithm: "HS256").first.with_indifferent_access
  rescue JWT::DecodeError
    nil
  end
end
