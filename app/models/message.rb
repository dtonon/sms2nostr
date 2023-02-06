require 'digest'
require 'encrypt'

class Message < ApplicationRecord

  # Sender is never saved to DB to increase the system's privacy
  attr_accessor :sender, :sos

  validates :provider_message_code, presence: true, uniqueness: true

  belongs_to :account, optional: true

  before_save :setup
  after_save :post_to_nostr

  # Extract passcode, check if sms format is valid and generate the signture id
  # Sms format is '<passcode>#<content>'
  def setup
    passcode, self.content, more = sms_payload.split('#')

    if Rails.application.config.settings[:antispam_mode] && (content.nil?)
      raise StandardError, 'Not valid sms2nostr message'
    elsif !Rails.application.config.settings[:antispam_mode] && (content.nil?)
      # Without antispam force the POST mode on plain messagge without a structure
      self.content = sms_payload
      passcode = "POST"
    end

    passcode.strip!
    content.strip!
    more&.strip!
    sender.gsub!(/[^0-9]/, '')

    case passcode.upcase
    when 'POST'
      # Post the message using a new key and associate it to the sender number
      account_signature = Digest::SHA256.hexdigest(sender)
      self.account = Account.find_or_create_by(signature: account_signature) # Use the message signature
      account.update_attribute(:private_key, Message.generate_private_key) if account.private_key.nil? # Generate only if new
      @nostr_private_key = account.private_key

    when 'RESET'
      # Post the message forcing a new key and associate it to the sender number
      account_signature = Digest::SHA256.hexdigest(sender)
      self.account = Account.find_or_create_by(signature: account_signature) # Use the message signature
      account.update_attribute(:private_key, Message.generate_private_key) # Generate always
      @nostr_private_key = account.private_key

    when 'LOGIN'
      # Set your own nsec with a pin
      raise StandardError, 'Missing PIN' if more.nil?

      account_signature = Digest::SHA256.hexdigest(sender + more)
      self.account = Account.find_or_create_by(signature: account_signature) # Use the message signature
      account.private_key = encrypt_string(content, more)
      account.save!
      
      unless Rails.application.config.settings[:dryrun_mode]
        self.sms_payload = '<LOGIN>'
        self.content = '<NSEC>'
      end

      @nostr_private_key = nil
      # Don't setting the key signal that is not a postable message

    when 'WIPE'
      # Wipe key/account and all the related messages from the DB.
      account_signature = Digest::SHA256.hexdigest(sender + content)
      a = Account.where(signature: account_signature).first
      a.try(:destroy)
      @nostr_private_key = nil
      # Don't setting the key signal that is not a postable message

    when 'BURN'
      # Post the message using a throwaway account
      @nostr_private_key = Message.generate_private_key

    when 'SOS'
      # # Use sms2nostr key and add an SOS image to highlight the message

      sos_mode
      # TODO: Load sms2nostr account
      raise "Error: SOS mode not available" unless Rails.application.config.settings[:sos_mode]
      raise "Error: Set the sms2nostr_host in config/settings.yml" unless Rails.application.config.settings[:sms2nostr_host]
      raise "Error: Set the sms2nostr_nsec in config/settings.yml" unless Rails.application.config.settings[:sms2nostr_nsec]

      @nostr_private_key = Nostr.to_hex(Rails.application.config.settings[:sms2nostr_nsec])

      content << "\nMy phone number is: #{sender}" if Rails.application.config.settings[:show_number_on_sos]
      content << "\nSOS generated by sms2nostr"
      content << "\n\n#{Rails.application.config.settings[:sms2nostr_host]}/sos.png"

    else
      # Search if the passcode exist as saved account and use it
      account_signature = Digest::SHA256.hexdigest(sender + passcode)
      self.account = Account.where(signature: account_signature).first
      @nostr_private_key = decrypt_string(account.private_key, passcode) if account
    end

  end

  def post_to_nostr

    return unless @nostr_private_key
    return if submited_at

    n = Nostr.new(private_key: @nostr_private_key)

    dm_recipient = Rails.application.config.settings[:dm_recipient]
    event = if dm_recipient && !sos
      n.build_dm_event(content, Nostr.to_hex(dm_recipient))
    else
      n.build_note_event(content)
    end
    update_column(:event, event.to_s)

    if Rails.application.config.settings[:dryrun_mode]
      puts "------------------------------\nSender:\n#{sender}"
      puts "------------------------------\nNpub:\n#{@nostr_private_key}"
    end

    puts "------------------------------\nMessage:\n#{content}"
    puts "------------------------------\n#{event}\n------------------------------"

    Rails.application.config.settings[:relays].each do |relay|
      puts "Posting to #{relay}"

      if !Rails.application.config.settings[:dryrun_mode]
        timer = 0
        response = nil
        timer_step = 0.1
        timeout = 5 # Seconds

        begin
          ws = WebSocket::Client::Simple.connect relay
          ws.on :message do |msg|
            puts msg
            response = JSON.parse(msg.data)
            ws.close if response[0] == 'OK'
          end
          ws.on :open do
            ws.send event.to_json
          end
          while timer < timeout && response.nil? do
            sleep timer_step
            timer += timer_step
          end
          ws.close
        rescue => e
          puts e.inspect
          ws.close
        end

        update_column(:submited_at, DateTime.now)
      end
    end
  end

  # TODO: Move to nostr-ruby
  def self.generate_private_key
    (1 + SecureRandom.random_number(ECDSA::Group::Secp256k1.order - 1)).to_s(16)
  end

end
