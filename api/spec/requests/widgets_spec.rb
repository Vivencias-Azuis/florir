require "rails_helper"

RSpec.describe "Widgets API", type: :request do
  describe "GET /widgets" do
    it "returns a JSON list of widgets" do
      get "/widgets"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /widgets" do
    it "creates a widget with valid params" do
      post "/widgets", params: { widget: { name: "Sample", description: "Example" } }

      expect(response).to have_http_status(:created)
    end
  end
end
