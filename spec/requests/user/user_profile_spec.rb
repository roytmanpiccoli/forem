require "rails_helper"

RSpec.describe "UserProfiles", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET /user" do
    it "renders to appropriate page" do
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    it "renders pins if any" do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      last_article = create(:article, user_id: user.id)
      create(:profile_pin, pinnable: last_article, profile: user)
      get "/#{user.username}"
      expect(response.body).to include "Pinned"
    end

    it "calls user by their username in the 'more info' area" do
      get "/#{user.username}"
      expect(response.body).to include "More info about @#{user.username}"
    end

    it "does not render pins if they don't exist" do
      get "/#{user.username}?i=i" # Pinned will still be present in layout file, but not the "internal" version
      expect(response.body).not_to include "Pinned"
    end

    it "renders profile page of user after changed username" do
      old_username = user.username
      user.update_columns(username: "new_username_yo_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      user.update_columns(username: "new_new_username_#{rand(10_000)}", old_username: user.username,
                          old_old_username: user.old_username)
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "raises not found for banished users" do
      banishable_user = create(:user)
      Moderator::BanishUser.call(admin: user, user: banishable_user)
      expect { get "/#{banishable_user.reload.old_username}" }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get "/#{banishable_user.reload.username}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises not found if user not registered" do
      user.update_column(:registered, false)
      expect { get "/#{user.username}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders noindex meta if suspended" do
      user.add_role(:suspended)
      get "/#{user.username}"
      expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
    end

    it "does not render noindex meta if not suspended" do
      get "/#{user.username}"
      expect(response.body).not_to include("<meta name=\"robots\" content=\"noindex\">")
    end

    it "renders rss feed link if any stories" do
      create(:article, user_id: user.id)

      get "/#{user.username}"
      expect(response.body).to include("/feed/#{user.username}")
    end

    it "does not render feed link if no stories" do
      get "/#{user.username}"
      expect(response.body).not_to include("/feed/#{user.username}")
    end

    it "renders user payment pointer if set" do
      user.update_column(:payment_pointer, "test-payment-pointer")
      get "/#{user.username}"
      expect(response.body).to include "author-payment-pointer"
      expect(response.body).to include "test-payment-pointer"
    end

    it "does not render payment pointer if not set" do
      get "/#{user.username}"
      expect(response.body).not_to include "author-payment-pointer"
    end

    it "renders sidebar profile field elements in sidebar" do
      create(:profile_field, label: "whoaaaa", display_area: "left_sidebar")
      get "/#{user.username}"
      # Ensure this comes after the start of the sidebar element
      expect(response.body.split("Whoaaaa").first).to include "crayons-layout__sidebar-left"
    end

    it "does not render special display header elements naively" do
      user.profile.update(location: "hawaii")
      get "/#{user.username}"
      # Does not include the word, but does include the SVG
      expect(response.body).not_to include "<p>Location</p>"
      expect(response.body).to include user.profile.location
      expect(response.body).to include "M18.364 17.364L12 23.728l-6.364-6.364a9 9 0 1112.728 0zM12 13a2 2 0 100-4 2 2 0"
    end

    context "when organization" do
      it "renders organization page if org" do
        get organization.path
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end

      it "renders organization users on sidebar" do
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response.body).to include user.profile_image_url
      end

      it "renders no sponsors if not sponsor" do
        get organization.path
        expect(response.body).not_to include "Gold Community Sponsor"
      end

      it "renders sponsor if it is sponsored" do
        create(:sponsorship, level: :gold, status: :live, organization: organization)
        get organization.path
        expect(response.body).to include "Gold Community Sponsor"
      end

      it "renders organization name properly encoded" do
        organization.update(name: "Org & < ' \" 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.name))
      end

      it "renders organization email properly encoded" do
        organization.update(email: "t&st&mail@dev.to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.email))
      end

      it "renders organization summary properly encoded" do
        organization.update(summary: "Org & < ' \" &quot; 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.summary))
      end

      it "renders organization location properly encoded" do
        organization.update(location: "123, ave dev & < ' \" &quot; to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.location))
      end

      it "renders rss feed link if any stories" do
        create(:article, organization_id: organization.id)
        get organization.path
        expect(response.body).to include("/feed/#{organization.slug}")
      end

      it "does not render feed link if no stories" do
        get organization.path
        expect(response.body).not_to include("/feed/#{organization.slug}")
      end
    end

    context "when displaying a GitHub repository on the profile" do
      let(:github_user) { create(:user, :with_identity, identities: %i[github]) }
      let(:params) do
        {
          description: "A book bot :robot:",
          featured: true,
          github_id_code: build(:github_repo).github_id_code,
          name: Faker::Book.title,
          stargazers_count: 1,
          url: Faker::Internet.url
        }
      end

      before do
        omniauth_mock_github_payload
      end

      it "renders emoji in description of featured repository" do
        GithubRepo.upsert(github_user, **params)

        get "/#{github_user.username}"
        expect(response.body).to include("A book bot 🤖")
      end

      it "does not show a non featured repository" do
        GithubRepo.upsert(github_user, **params.merge(featured: false))

        get "/#{github_user.username}"
        expect(response.body).not_to include("A book bot 🤖")
      end

      it "does not render anything if the user has not authenticated through GitHub" do
        get "/#{github_user.username}"
        expect(response.body).not_to include("github-repos-container")
      end
    end
  end

  describe "redirect to moderation" do
    it "redirects to admin" do
      user = create(:user)
      get "/#{user.username}/admin"
      expect(response.body).to redirect_to edit_admin_user_path(user.id)
    end

    it "redirects to moderate" do
      user = create(:user)
      get "/#{user.username}/moderate"
      expect(response.body).to redirect_to admin_user_path(user.id)
    end
  end
end
