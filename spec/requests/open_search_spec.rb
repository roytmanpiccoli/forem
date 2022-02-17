require "rails_helper"

RSpec.describe "OpenSearch", type: :request do
  let(:user) { create(:user, saw_onboarding: false) }

  describe "GET /open-search.xml" do
    it "has proper information" do
      get "/open-search.xml"
      expect(response.body).to include("<ShortName>#{Settings::Community.community_name} Search</ShortName>")
    end
  end
end
