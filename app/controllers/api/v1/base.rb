module API
  module V1
    class Base < Grape::API
      mount API::V1::Textmagic
      mount API::V1::IncomingSmsForwarder
      mount API::V1::Messagebird
    end
  end
end