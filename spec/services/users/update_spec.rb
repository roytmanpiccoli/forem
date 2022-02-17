require "rails_helper"

RSpec.describe Users::Update, type: :service do
  def sidekiq_assert_resave_article_worker(user, &block)
    sidekiq_assert_enqueued_with(
      job: Users::ResaveArticlesWorker,
      args: [user.id],
      queue: "medium_priority",
      &block
    )
  end

  let(:profile) do
    create(:profile, data: { test_field: "maybe", removed: "Bla" })
  end
  let(:user) { profile.user }

  it "automatically creates a profile for a user if it does not exist" do
    user = create(:user, _skip_creating_profile: true)

    expect(user.profile).to be_nil

    described_class.call user, profile: { location: "Over here" }

    expect(user.profile).to be_a Profile
  end

  it "correctly typecasts new attributes", :aggregate_failures do
    described_class.call(user, profile: { location: 123 })
    expect(user.profile.location).to eq "123"
  end

  it "removes old attributes from the profile" do
    expect do
      described_class.call(user, profile: {})
    end.to change { profile.data.key?("removed") }.to(false)
  end

  it "propagates changes to user", :aggregate_failures do
    new_name = "Sloan Doe"
    described_class.call(user, profile: {}, user: { name: new_name })
    expect(profile.user.name).to eq new_name
  end

  it "updates the profile_updated_at column" do
    create(:profile_field, label: "Test field")
    expect do
      described_class.call(user, profile: { test_field: "false" })
    end.to change { user.reload.profile_updated_at }
  end

  it "returns an error if Profile image is too large" do
    profile_image = fixture_file_upload("large_profile_img.jpg", "image/jpeg")
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "Profile image File size should be less than 2 MB"
  end

  it "returns an error if Profile image is not a file" do
    profile_image = "A String"
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "invalid file type. Please upload a valid image."
  end

  it "returns an error if Profile image file name is too long" do
    profile_image = fixture_file_upload("800x600.png", "image/png")
    allow(profile_image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "filename too long - the max is 250 characters."
  end

  context "when changing username" do
    let(:new_username) { "#{user.username}_changed" }

    it "sets old_username and old_old_username when username was changed" do
      old_username = user.username
      old_old_username = user.old_username
      described_class.call(user, user: { username: new_username })
      user.reload
      expect(user.username).to eq(new_username)
      expect(user.old_username).to eq(old_username)
      expect(user.old_old_username).to eq(old_old_username)
    end

    it "changes user's articles path" do
      article = create(:article, user: user)
      old_path = article.path
      sidekiq_perform_enqueued_jobs do
        described_class.call(user, user: { username: new_username })
      end
      article.reload
      expect(article.path).not_to eq(old_path)
      expect(article.path).to eq("/#{new_username}/#{article.slug}")
    end

    # testing against gsub'ing username
    it "sets the correct article path when its slug contains username" do
      article = create(:article, user: user, slug: "#{user.username}-hello")
      old_path = article.path
      sidekiq_perform_enqueued_jobs do
        described_class.call(user, user: { username: new_username })
      end
      article.reload
      expect(article.path).not_to eq(old_path)
      expect(article.path).to eq("/#{new_username}/#{article.slug}")
    end
  end

  context "when conditionally resaving articles" do
    it "enqueues resave articles job when changing username" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { username: "#{user.username}_changed" })
      end
    end

    it "enqueues resave articles job when changing profile_image" do
      profile_image = fixture_file_upload("800x600.jpg")

      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { profile_image: profile_image })
      end
    end

    it "enqueues resave articles job when changing name" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { name: "#{user.name} changed" })
      end
    end

    it "enqueues resave articles job when changing summary" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, profile: { summary: "#{user.profile.summary} changed" })
      end
    end

    it "enqueues resave articles job when changing bg_color_hex" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user_settings: { brand_color1: "#12345F" })
      end
    end

    it "enqueues resave articles job when changing text_color_hex" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user_settings: { brand_color2: "#12345F" })
      end
    end

    Authentication::Providers.username_fields.each do |username_field|
      it "enqueues resave articles job when changing #{username_field}" do
        sidekiq_assert_resave_article_worker(user) do
          described_class.call(user, user: { username_field => "greatnewusername" })
        end
      end

      it "doesn't enqueue resave articles job when changing #{username_field} for a suspended user" do
        suspended_user = create(:user, :suspended)

        expect do
          described_class.call(suspended_user, user: { username_field => "greatnewusername" })
        end.not_to change(Users::ResaveArticlesWorker.jobs, :size)
      end
    end
  end
end
