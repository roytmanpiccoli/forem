require "rails_helper"

RSpec.describe Authentication::Providers::Forem, type: :service do
  describe ".authentication_path" do
    it "returns the correct authentication path" do
      expected_path = Rails.application.routes.url_helpers.user_forem_omniauth_authorize_path
      expect(described_class.authentication_path).to eq(expected_path)
    end

    it "supports additional parameters" do
      path = described_class.authentication_path(state: "state")
      expect(path).to include("state=state")
    end
  end

  describe ".sign_in_path" do
    let(:expected_path) do
      expected_callback_url = CGI.escape(URL.url("/users/auth/forem/callback"))
      "/users/auth/forem?callback_url=#{expected_callback_url}"
    end

    it "returns the correct sign in path" do
      expect(described_class.sign_in_path).to eq(expected_path)
    end

    it "supports additional parameters" do
      path = described_class.sign_in_path(state: "state")
      expect(path).to include("state=state")
    end

    it "does not override the callback_url parameter" do
      path = described_class.sign_in_path(callback_url: "https://example.com/callback")
      expect(path).to eq(expected_path)
    end
  end
end
