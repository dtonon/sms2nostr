module API
  module V1
    class Messages < Grape::API
      include API::V1::Defaults

      resources :messages do
        desc 'Fetch messages '
        params do
          requires :signature, type: String, desc: 'Message signature'
        end
        post 'fetch' do
          message = Message.where(signature: params[:signature]).first
          if message
            status 200
            {
              signature: message.signature,
              content: message.content,
              created_at: message.created_at
            }.to_json
          else
            status 404
            {error: 'Not found'}
          end
        end
      end
    end
  end
end