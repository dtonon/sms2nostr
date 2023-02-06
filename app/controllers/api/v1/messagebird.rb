require 'digest'

module API
  module V1
    class Messagebird < Grape::API
      include API::V1::Defaults

      resources :messagebird do
        desc 'Fetch SMS via Android Incoming SMS Forwarder App'
        params do
          requires :from, type: String, desc: 'Sender phone'
          requires :text, type: String, desc: 'Message text'
        end
        post 'fetch' do

          puts params

          begin
            check_message = Message.where(provider_message_code: params[:id]).first
            if check_message && ((check_message.created_at + 1.hour) > DateTime.now)
              # Sms already retrivied
              return { status: 'Ok', note: 'Duplicate' }
            else
              Message.create!(
                provider_message_code: params[:id].strip,
                sender: params[:from].strip,
                sms_payload: params[:text].strip
              )
            end

            return { status: 'Ok' }
          rescue StandardError => e
            # TODO: log and notify
            puts e.message
            error!(e.message, 422)
          end
        end
      end
    end
  end
end