require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220128150709_add_admin_member_view_feature_flag.rb",
)

describe DataUpdateScripts::AddAdminMemberViewFeatureFlag do
  after do
    FeatureFlag.remove(:admin_member_view)
  end

  it "adds the :admin_member_view flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:admin_member_view) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:admin_member_view)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:admin_member_view) }
  end
end
