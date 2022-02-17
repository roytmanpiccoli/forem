require "rails_helper"

RSpec.describe "Visiting article comments", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let!(:comment) { create(:comment, commentable: article, user: user) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment) }
  let!(:grandchild_comment) { create(:comment, commentable: article, parent: child_comment) }

  before do
    create(:comment, commentable: article, parent: comment)
    comments = create_list(:comment, 3, commentable: article)
    create(:comment, commentable: article, parent: comments.sample)
    sign_in user
  end

  context "when all comments" do
    before { visit "#{article.path}/comments" }

    it "displays comments" do
      expect(page).to have_selector(".single-comment-node", visible: :visible, count: 8)
    end

    it "displays child comments" do
      expect(page).to have_selector(".comment--deep-1", visible: :visible, count: 3)
    end

    it "displays grandchild comments" do
      expect(page).to have_selector(".comment--deep-2#comment-node-#{grandchild_comment.id}", visible: :visible,
                                                                                              count: 1)
    end
  end

  context "when root is specified" do
    before { visit "#{article.path}/comments/#{comment.id.to_s(26)}" }

    it "displays related comments" do
      expect(page).to have_selector(".single-comment-node", visible: :visible, count: 4)
    end

    it "displays child comments" do
      expect(page).to have_selector(".comment--deep-1", visible: :visible, count: 2)
    end

    it "displays grandchild comments" do
      expect(page).to have_selector(".comment--deep-2#comment-node-#{grandchild_comment.id}", visible: :visible,
                                                                                              count: 1)
    end
  end
end
