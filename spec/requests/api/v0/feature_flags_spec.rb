require "rails_helper"

RSpec.describe "Api::V0::FeatureFlagsController", type: :request do
  let(:flag) { "test_flag" }
  let(:params) { { flag: flag } }

  it "is not available in the production environment" do
    # We really need an ActiveSupport::StringInquirer here
    # rubocop:disable Rails/Inquiry
    allow(Rails).to receive(:env).and_return("production".inquiry)
    # rubocop:enable Rails/Inquiry

    expect do
      post api_feature_flags_path, params: params
    end.to raise_error(ActionController::RoutingError)
  end

  context "when toggling feature flags" do
    before { FeatureFlag.add(flag) }

    after { FeatureFlag.remove(flag) }

    it "can enable a disabled feature flag" do
      FeatureFlag.disable(flag)

      expect do
        post api_feature_flags_path, params: params
      end.to change { FeatureFlag.enabled?(flag) }.from(false).to(true)
    end

    it "keeps the flag enabled when it was already enabled" do
      FeatureFlag.enable(flag)

      expect do
        post api_feature_flags_path, params: params
      end.not_to change { FeatureFlag.enabled?(flag) }.from(true)
    end

    it "can disable an enabled feature flag" do
      FeatureFlag.enable(flag)

      expect do
        delete api_feature_flags_path, params: params
      end.to change { FeatureFlag.enabled?(flag) }.from(true).to(false)
    end

    it "keeps the flag disabled when it was already disabled" do
      FeatureFlag.disable(flag)

      expect do
        delete api_feature_flags_path, params: params
      end.not_to change { FeatureFlag.enabled?(flag) }.from(false)
    end

    it "shows the current value of a feature flag" do
      FeatureFlag.enable(flag)

      get api_feature_flags_path(flag: flag)

      parsed_response = JSON.parse(response.body)
      expect(parsed_response[flag]).to be true
    end
  end
end
