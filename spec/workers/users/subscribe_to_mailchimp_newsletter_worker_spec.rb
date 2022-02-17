require "rails_helper"

RSpec.describe Users::SubscribeToMailchimpNewsletterWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform_now" do
    let(:worker) { subject }
    let(:user) { create(:user) }

    it "subscribes user to mailchimp newsletter" do
      mailchimp_bot = double
      allow(Mailchimp::Bot).to receive(:new).and_return(mailchimp_bot)
      allow(mailchimp_bot).to receive(:upsert)

      worker.perform(user.id)

      expect(mailchimp_bot).to have_received(:upsert)
    end

    it "does not subscribe the user if they don't have an email" do
      mailchimp_bot = double
      allow(Mailchimp::Bot).to receive(:new).and_return(mailchimp_bot)
      allow(mailchimp_bot).to receive(:upsert)
      user.update! email: nil

      worker.perform(user.id)

      expect(mailchimp_bot).not_to have_received(:upsert)
    end
  end
end
