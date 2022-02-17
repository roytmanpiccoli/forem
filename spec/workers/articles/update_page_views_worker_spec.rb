require "rails_helper"

RSpec.describe Articles::UpdatePageViewsWorker, type: :worker do
  let(:worker) { described_class.new }

  context "when the article is unpublished" do
    subject(:perform) { worker.perform(article_id: article.id) }

    let(:article) { create(:article, published: false, published_at: nil) }

    it "does not create a page view" do
      expect { perform }.not_to change(PageView, :count)
    end
  end

  context "when the article is published and written by the given user" do
    subject(:perform) { worker.perform(article_id: article.id, user_id: article.user_id) }

    let(:article) { create(:article) }

    it "does not create a page view" do
      expect { perform }.not_to change(PageView, :count)
    end
  end

  context "when the article id is invalid" do
    let(:article_id) { :no_article_with_this_id }

    it "exits gracefully" do
      expect { worker.perform(article_id: article_id) }.not_to raise_error
    end

    it "does not attempt to create a page view for an invalid article" do
      allow(PageView).to receive(:create!)

      worker.perform(article_id: article_id)

      expect(PageView).not_to have_received(:create!)
    end
  end

  context "when the article exists" do
    let(:user) { create(:user) }
    let(:referrer) { nil }
    let(:article) { create(:article) }

    it "creates a page view" do
      expect do
        worker.perform("article_id" => article.id,
                       "user_id" => user.id,
                       "referrer" => referrer)
      end.to change(PageView, :count).by(1)
    end
  end
end
