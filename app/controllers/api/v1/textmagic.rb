module API
  module V1
    class Textmagic < Grape::API
      include API::V1::Defaults

      resources :textmagic do
        desc 'Fetch SMS via TextMagic'
        params do
          requires :sender, type: String, desc: 'Sender phone'
          requires :text, type: String, desc: 'Message text'
        end
        post 'fetch' do
          begin
            check_message = Message.where(provider_message_code: params[:id]).first
            if check_message && ((check_message.created_at + 1.hour) > DateTime.now)
              # Sms already retrivied
              return { status: 'Ok', note: 'Duplicate' }
            else
              Message.create!(
                provider_message_code: params[:id].strip,
                sender: "+#{params[:sender].strip}",
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