module API
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix "api"
        version "v1", using: :path, vendor: 'sms2nostr.vitamino.it'
        content_type :json, 'application/json; charset=UTF-8'
        default_format :json
        format :json

        # helpers API::Helpers::AuthenticationHelper
      end
    end
  end
end  