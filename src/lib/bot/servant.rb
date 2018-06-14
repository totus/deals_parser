module Servant
  def send_message(destination, message, params = {})
    send_message_to(destination, message, params)
  end

  def process_messages(messages_info)
    accept_messages(messages_info)
  end
end