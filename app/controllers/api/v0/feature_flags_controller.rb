module Api
  module V0
    # This controller is used for toggling feature flags in the test
    # environment, specifically for Cypress tests.
    #
    # @note: Despite the used methods this controller does not add or remove
    # the flags themselves, I just wanted distinct methods for enabling and
    # disabling so we don't need conditional or boolean casting and these were
    # the most fitting actions.
    class FeatureFlagsController < ApiController
      def create
        FeatureFlag.enable(params[:flag])
        head :ok
      end

      def show
        flag = params[:flag]
        render json: { flag => FeatureFlag.enabled?(flag) }
      end

      def destroy
        FeatureFlag.disable(params[:flag])
        head :ok
      end
    end
  end
end
