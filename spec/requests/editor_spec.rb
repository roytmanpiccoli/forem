require "rails_helper"

RSpec.describe "Editor", type: :request do
  describe "GET /new" do
    context "when not logged-in" do
      it "asks the non logged in user to sign in" do
        get new_path

        # NOTE: [@jeremyf] This response status seems a bit surprising.  Should the prompt for signin redirect
        # the user to a login page?  Or are we doing something with Javascript?  For now, paint me
        # curious, but not enough to pull on this thread.
        expect(response).to have_http_status(:ok)
      end
    end

    context "when email login is allowed in /admin/customization/config" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_login).and_return(true)
      end

      it "asks the non logged in user to sign in, with email signin enabled" do
        get new_path

        expect(response.body).to include("Email")
        expect(response.body).to include("Password")
      end
    end
  end

  describe "GET /:article/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when not logged-in" do
      it "redirects to /enter" do
        get "/username/article/edit"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged-in" do
      it "render markdown form" do
        sign_in user
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /articles/preview" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }

    context "when not logged-in" do
      it "redirects to /enter" do
        post "/articles/preview", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in" do
      it "returns json" do
        sign_in user
        post "/articles/preview", headers: headers
        expect(response.media_type).to eq("application/json")
      end
    end

    context "with front matter" do
      it "returns successfully" do
        sign_in user
        article_body = <<~MARKDOWN
          ---
          ---

          Hello
        MARKDOWN

        post "/articles/preview",
             headers: headers,
             params: { article_body: article_body },
             as: :json

        expect(response).to be_successful
      end
    end
  end
end
