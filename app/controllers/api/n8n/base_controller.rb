module Api
  module N8n
    class BaseController < Api::BaseController
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_n8n_token!

      private

        def authenticate_n8n_token!
          token = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
          expected = ENV["N8N_API_TOKEN"]
          head :unauthorized unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
        end
    end
  end
end
