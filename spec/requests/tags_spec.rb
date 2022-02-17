require "rails_helper"

RSpec.describe "Tags", type: :request, proper_status: true do
  describe "GET /tags" do
    it "returns proper page" do
      create(:tag, name: "ruby")
      create(:tag, name: "javascript", alias_for: "")

      get tags_path
      expect(response.body).to include("Top tags", "ruby", "javascript")
    end

    it "does not include tags with alias" do
      create(:tag, name: "ruby")
      create(:tag, name: "aliastag", alias_for: "ruby")

      get tags_path
      expect(response.body).not_to include("aliastag")
    end

    it "searches tags", :aggregate_failures do
      %w[ruby java javascript].each { |t| create(:tag, name: t) }

      get tags_path(q: "ruby")
      expect(response.body).to include("Search results for ruby", "ruby")
      expect(response.body).not_to include("javascript")

      get tags_path(q: "java")
      expect(response.body).to include("Search results for java", "java", "javascript")
      expect(response.body).not_to include("ruby")

      get tags_path(q: "yeet")
      expect(response.body).to include("No results match that query")
    end
  end

  describe "GET /tags/suggest" do
    it "returns a JSON representation of the top tags", :aggregate_failures do
      badge = create(:badge)
      tag = create(:tag, badge: badge)

      get suggest_tags_path

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/json; charset=utf-8}i)
      response_tag = JSON.parse(response.body).first
      expect(response_tag["name"]).to eq(tag.name)
      expect(response_tag).to have_key("rules_html")
      expect(response_tag).to have_key("short_summary")
      expect(response_tag).to have_key("bg_color_hex")
      expect(response_tag).to have_key("badge")
      expect(response_tag["badge"]).to have_key("badge_image")
    end
  end

  describe "GET /t/:tag/edit" do
    let(:tag)                  { create(:tag) }
    let(:another_tag)          { create(:tag) }
    let(:unauthorized_user)    { create(:user) }
    let(:tag_moderator)        { create(:user) }
    let(:super_admin)          { create(:user, :super_admin) }

    before do
      allow(Settings::General).to receive(:suggested_tags).and_return(%w[beginners javascript career])
    end

    it "does not allow not logged-in users" do
      get "/t/#{tag}/edit"
      expect(response).to redirect_to("/enter")
    end

    it "does not allow users who are not tag moderators" do
      sign_in unauthorized_user
      get "/t/#{tag}/edit"
      expect(response).to have_http_status(:not_found)
    end

    it "allows super admins" do
      sign_in super_admin
      get "/t/#{tag}/edit"
      expect(response.body).to include(I18n.t("views.tags.edit.help"))
    end

    context "when user is a tag moderator" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
      end

      it "allows authorized tag moderators" do
        get "/t/#{tag}/edit"
        expect(response.body).to include(I18n.t("views.tags.edit.help"))
      end

      it "does not allow moderators of one tag to edit another tag" do
        get "/t/#{another_tag}/edit"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "UPDATE /tags" do
    valid_params = { tag: { text_color_hex: "", bg_color_hex: "" } }
    let(:tag)                  { create(:tag) }
    let(:another_tag)          { create(:tag) }
    let(:unauthorized_user)    { create(:user) }
    let(:tag_moderator)        { create(:user) }
    let(:super_admin)          { create(:user, :super_admin) }

    it "does not allow not logged-in users" do
      patch "/tag/#{tag.id}"
      expect(response).to redirect_to("/enter")
    end

    it "does not allow unauthorized users" do
      sign_in unauthorized_user
      patch "/tag/#{tag.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "allows super admins" do
      sign_in super_admin
      patch "/tag/#{tag.id}", params: valid_params
      expect(response).to redirect_to("/t/#{tag}/edit")
    end

    context "when user is a tag moderator" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
      end

      it "allows authorized tag moderators to update a tag" do
        patch "/tag/#{tag.id}", params: valid_params
        expect(response).to redirect_to("/t/#{tag}/edit")
      end

      it "updates updated_at for tag" do
        tag.update_column(:updated_at, 2.weeks.ago)
        patch "/tag/#{tag.id}", params: valid_params
        expect(tag.reload.updated_at).to be > 1.minute.ago
      end

      it "displays proper error messages" do
        invalid_text_color_hex = "udjsadasfkdjsa"
        patch "/tag/#{tag.id}", params: {
          tag: { text_color_hex: invalid_text_color_hex, bg_color_hex: "" }
        }
        expect(response.body).to include("Text color hex is invalid")
      end

      it "does not allow moderators of one tag to edit another tag" do
        patch("/tag/#{another_tag.id}", params: valid_params)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /tags/onboarding" do
    let(:headers) do
      {
        Accept: "application/json",
        "Content-Type": "application/json"
      }
    end

    before do
      allow(Settings::General).to receive(:suggested_tags).and_return(%w[beginners javascript career])
    end

    it "returns tags" do
      create(:tag, name: Settings::General.suggested_tags.first)

      get onboarding_tags_path, headers: headers

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      tag = create(:tag, name: Settings::General.suggested_tags.first)

      get onboarding_tags_path, headers: headers

      response_tag = response.parsed_body.first
      expect(response_tag.keys).to match_array(%w[id name bg_color_hex text_color_hex following])
      expect(response_tag["id"]).to eq(tag.id)
      expect(response_tag["name"]).to eq(tag.name)
      expect(response_tag["bg_color_hex"]).to eq(tag.bg_color_hex)
      expect(response_tag["text_color_hex"]).to eq(tag.text_color_hex)
      expect(response_tag[I18n.t("core.following")]).to be_nil
    end

    it "returns only suggested tags" do
      not_suggested_tag = create(:tag, name: "definitelynotasuggestedtag")

      get onboarding_tags_path, headers: headers

      expect(response.parsed_body.filter { |t| t["name"] == not_suggested_tag.name }).to be_empty
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, name: Settings::General.suggested_tags.first)

      get onboarding_tags_path, headers: headers

      expected_key = ["tags", tag.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end
end
