require 'digest'

module API
  module V1
    class ProviderTemplate < Grape::API
      include API::V1::Defaults

      resources :provider_template do
        desc 'Fetch SMS via custom provider'
        params do
          requires :from, type: String, desc: 'Sender phone'
          requires :text, type: String, desc: 'Message text'
        end
        post 'fetch' do

          # Generate a unique code if the provider doesn't give one
          code = Digest::MD5.hexdigest(params[:from] + params[:text])

          begin
            check_message = Message.where(provider_message_code: code).first
            if check_message && ((check_message.created_at + 1.hour) > DateTime.now)
              # Sms already retrivied
              return { status: 'Ok', note: 'Duplicate' }
            else
              Message.create!(
                provider_message_code: Digest::MD5.hexdigest(params[:from] + params[:text]),
                sender: params[:from],
                sms_payload: params[:text].strip
              )
            end

            return { status: 'Ok' }
          rescue StandardError => e
            # TODO: log and notify
            error!(e.message, 422)
          end
        end
      end
    end
  end
end