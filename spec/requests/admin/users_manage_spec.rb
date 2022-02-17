require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:user) { create(:user, twitter_username: nil, old_username: "username") }
  let!(:user2) { create(:user, twitter_username: "Twitter") }
  let(:user3) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user2) }
  let(:badge) { create(:badge, title: "one-year-club") }
  let(:organization) { create(:organization) }
  let(:rewarder) { create(:user) }

  before do
    sign_in super_admin
    dependents_for_offending_user_article
    offender_activity_on_other_content
  end

  def dependents_for_offending_user_article
    # create user2 comment on offending user article
    comment = create(:comment, commentable_type: "Article", commentable: article, user: user2)
    # create user3 reaction to user2 comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    # create user3 comment response to user2 comment
    comment2 = create(:comment, commentable_type: "Article", commentable: article, user: user3, ancestry: comment.id,
                                body_markdown: "Hello @#{user2.username}, you are cool.")
    # create user2 reaction to user3 comment response
    create(:reaction, reactable: comment2, reactable_type: "Comment", user: user2)
    # create user3 reaction to offending article
    create(:reaction, reactable: article, reactable_type: "Article", user: user3, category: "like")
    sidekiq_perform_enqueued_jobs do
      Mention.create_all(comment2)
    end
  end

  def offender_activity_on_other_content
    # offender reacts to user2 article
    create(:reaction, reactable: article2, reactable_type: "Article", user: user)
    # offender comments on user2 article
    comment = create(:comment, commentable_type: "Article", commentable: article2, user: user)
    # user3 reacts to offender comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
  end

  def full_profile
    BadgeAchievement.create(
      user_id: user2.id,
      badge_id: badge.id,
      rewarding_context_message_markdown: "message",
    )
    user2.follow(user3)
    user.follow(super_admin)
    user3.follow(user2)
    params = {
      name: Faker::Book.title,
      user_id: user2.id,
      github_id_code: rand(1000),
      url: Faker::Internet.url
    }
    GithubRepo.create(params)
  end

  context "when merging users" do
    before do
      full_profile
    end

    it "deletes duplicate user" do
      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect { User.find(user2.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "merges all content" do
      expected_articles_count = user.articles.count + user2.articles.count
      expected_comments_count = user.comments.count + user2.comments.count
      expected_reactions_count = user.reactions.count + user2.reactions.count

      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect(user.comments.count).to eq(expected_articles_count)
      expect(user.articles.count).to eq(expected_comments_count)
      expect(user.reactions.count).to eq(expected_reactions_count)
    end

    it "merges all relationships" do
      expected_follows_count = user.follows.count + user2.follows.count
      expected_mentions_count = user.mentions.count + user2.mentions.count

      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect(user.follows.count).to eq(expected_follows_count)
      expect(Follow.followable_user(user.id).count).to eq(1)
      expect(user.mentions.count).to eq(expected_mentions_count)
    end

    it "merges misc profile info" do
      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect(user.github_repos.any?).to be true
      expect(user.badge_achievements.any?).to be true
    end

    it "merges social identities and usernames" do
      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect(user.reload.twitter_username).to eq("Twitter")
    end

    it "merges an identity on a single account into the other" do
      omniauth_mock_twitter_payload
      omniauth_mock_github_payload
      create(:identity, user: user, provider: "twitter")
      deleted_user_identity = create(:identity, user: user2)

      post merge_admin_user_path(user.id), params: { user: { merge_user_id: user2.id } }

      expect(user.identities.count).to eq 2
      expect(user.identity_ids).to include deleted_user_identity.id
    end
  end

  context "when managing activity and roles" do
    it "adds comment suspend role" do
      params = { user: { user_status: "Comment Suspend", note_for_current_role: "comment suspend this user" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.roles.first.name).to eq("comment_suspended")
      expect(Note.first.content).to eq("comment suspend this user")
    end

    it "selects new role for user" do
      user.add_role(:trusted)
      user.reload

      params = { user: { user_status: "Comment Suspend", note_for_current_role: "comment suspend this user" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.roles.count).to eq(1)
      expect(user.roles.last.name).to eq("comment_suspended")
    end

    it "selects super admin role when user was suspended" do
      user.add_role(:suspended)
      user.reload

      params = { user: { user_status: "Super Admin", note_for_current_role: "they deserve it for some reason" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.super_admin?).to be(true)
    end

    it "does not allow non-super-admin to doll out admin" do
      super_admin.remove_role(:super_admin)
      super_admin.add_role(:super_admin)
      super_admin.reload

      params = { user: { user_status: "Super Admin", note_for_current_role: "they deserve it for some reason" } }
      patch user_status_admin_user_path(user.id), params: params

      expect(user.super_admin?).not_to be false
    end

    it "creates a general note on the user" do
      put admin_user_path(user.id), params: { user: { new_note: "general note about whatever" } }
      expect(Note.last.content).to eq("general note about whatever")
    end

    it "remove credits from account" do
      create_list(:credit, 5, user: user)
      put admin_user_path(user.id), params: { user: { remove_credits: "3" } }
      expect(user.credits.size).to eq(2)
    end

    it "removes non-admin roles from non-super_admin users", :aggregate_failures do
      user.add_role(:trusted)

      expect do
        delete admin_user_path(user.id), params: { user_id: user.id, role: :trusted }
      end.to change(user.roles, :count).by(-1)

      expect(user.has_trusted_role?).to be false
      expect(request.flash["success"]).to include("successfully removed from the user!")
    end

    it "removes the correct resource_admin_role from non-super_admin users", :aggregate_failures do
      user.add_role(:single_resource_admin, Comment)
      user.add_role(:single_resource_admin, Broadcast)

      expect do
        delete admin_user_path(user.id),
               params: { user_id: user.id, role: :single_resource_admin, resource_type: Comment }
      end.to change(user.roles, :count).by(-1)

      expect(user.single_resource_admin_for?(Comment)).to be false
      expect(user.single_resource_admin_for?(Broadcast)).to be true
      expect(request.flash["success"]).to include("successfully removed from the user!")
    end

    it "does not allow super_admin roles to be removed", :aggregate_failures do
      user.add_role(:super_admin)

      expect do
        delete admin_user_path(user.id), params: { user_id: user.id, role: :super_admin }
      end.not_to change(user.roles, :count)

      expect(user.super_admin?).to be true
      expect(request.flash["danger"]).to include("cannot be removed.")
    end

    it "does not allow a admins to remove a role from themselves", :aggregate_failures do
      super_admin.add_role(:trusted)

      expect do
        delete admin_user_path(super_admin.id), params: { user_id: super_admin.id, role: :trusted }
      end.not_to change(super_admin.roles, :count)

      expect(super_admin.trusted?).to be true
      expect(request.flash["danger"]).to include("cannot remove roles")
    end
  end

  context "when deleting user" do
    def create_mention
      comment = create(
        :comment,
        body_markdown: "Hello @#{user.username}, you are cool.",
        user_id: user2.id,
        commentable: article2,
      )
      sidekiq_perform_enqueued_jobs do
        Mention.create_all(comment)
      end
    end

    def create_mutual_follows
      user.follow(user3)
      follow = user3.follow(user)
      Notification.send_new_follower_notification_without_delay(follow)
    end

    before do
      create_mutual_follows
      create_mention
      create(:badge_achievement, rewarder: rewarder, rewarding_context_message: "yay", user: user)
    end

    it "raises a 'record not found' error after deletion" do
      sidekiq_perform_enqueued_jobs do
        post full_delete_admin_user_path(user.id)
      end
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "expect flash message" do
      post full_delete_admin_user_path(user.id)
      expect(request.flash["success"]).to include("fully deleted")
    end
  end

  context "when handling credits" do
    before do
      create(:organization_membership, user: super_admin, organization: organization, type_of_user: "admin")
    end

    it "adds the proper amount of credits for organizations" do
      put admin_user_path(super_admin.id), params: {
        user: {
          add_org_credits: 5,
          organization_id: organization.id
        }
      }
      expect(organization.reload.credits_count).to eq 5
      expect(organization.reload.unspent_credits_count).to eq 5
    end

    it "removes the proper amount of credits for organizations" do
      Credit.add_to(organization, 10)
      put admin_user_path(super_admin.id), params: {
        user: {
          remove_org_credits: 5,
          organization_id: organization.id
        }
      }
      expect(organization.reload.credits_count).to eq 5
      expect(organization.reload.unspent_credits_count).to eq 5
    end

    it "add the proper amount of credits to a user" do
      put admin_user_path(super_admin.id), params: {
        user: {
          add_credits: 5
        }
      }
      expect(super_admin.reload.credits_count).to eq 5
      expect(super_admin.reload.unspent_credits_count).to eq 5
    end

    it "removes the proper amount of credits from a user" do
      Credit.add_to(super_admin, 10)
      put admin_user_path(super_admin.id), params: {
        user: {
          remove_credits: 5
        }
      }
      expect(super_admin.reload.credits_count).to eq 5
      expect(super_admin.reload.unspent_credits_count).to eq 5
    end
  end
end
