require 'uri'

require 'aws-record'
require 'twilio-ruby'

module LambdaFunctions
  class Handler
    MESSAGE = ENV['MESSAGE']

    def self.process(event:, context:)
      puts 'ios_button_handler process started.'
      puts event
      puts context

      click_type = event.dig('deviceEvent', 'buttonClicked', 'clickType')
      device_id = event.dig('deviceInfo', 'deviceId')
      phone_call_handler = PhoneCallHandler.new(device_id)

      # Ckeck click type and select actions.
      case click_type
      when 'SINGLE'
        phone_call_handler.try_to_start_phone_call(MESSAGE)
      when 'DOUBLE'
        phone_call_handler.cancel_current_phone_call
      when 'LONG'
        phone_call_handler.toggle_phone_call_mute
      else
        raise 'Unknown click type.'
      end

      puts 'ios_button_handler process finished.'
    rescue => e
      puts "Error: #{e.message}"
      raise e
    end
  end

  class PhoneCallHandler
    TWILIO_ACCOUNT = ENV['TWILIO_ACCOUNT']
    TWILIO_TOKEN   = ENV['TWILIO_TOKEN']
    TWILIO_TEL     = ENV['TWILIO_TEL']
    TARGET_TEL     = ENV['TARGET_TEL']

    def initialize(device_id)
      @device_id = device_id
      @twilio = TwilioClient.new(TWILIO_ACCOUNT, TWILIO_TOKEN)
    end

    def try_to_start_phone_call(message)
      state = PhoneCallState.find_or_initialize(@device_id)
      if state.mute
        puts 'Do not start calling since mute mode is ON.'
        return
      end

      call = @twilio.start_phone_call(TWILIO_TEL, TARGET_TEL, message)
      state.sid = call.sid
      state.tel = TARGET_TEL
      state.save
    end

    def cancel_current_phone_call
      state = PhoneCallState.find_or_initialize(@device_id)
      if not state.sid
        puts 'Do not cancel call since there are no calling now.'
        return
      end

      @twilio.terminate_phone_call(state.sid)
      state.sid = nil
      state.tel = nil
      state.save
    end

    def toggle_phone_call_mute
      state = PhoneCallState.find_or_initialize(@device_id)
      state.mute = !state.mute
      state.save
    end
  end

  class TwilioClient
    def initialize(account_sid, auth_token)
      @client = Twilio::REST::Client.new account_sid, auth_token
    end

    def start_phone_call(from, to, message)
      @client.api.account.calls.create(
        from: from,
        to:   to,
        url:  "http://twimlets.com/message?Message[0]=#{URI::encode(message)}",
      )
    end

    def terminate_phone_call(sid)
      @client.calls(sid)
             .update(status: :completed)
    end
  end

  class PhoneCallState
    include Aws::Record

    set_table_name ENV['TABLE_NAME']
    string_attr :device_id, hash_key: true
    string_attr :sid
    string_attr :tel
    boolean_attr :mute, default_value: false

    def self.find_or_initialize(device_id)
      state = self.find(device_id: device_id)
      state = self.new(device_id: device_id) if state.nil?
      state
    end
  end
end

