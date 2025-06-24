 module Api
  module V1
    class WhatsappController < ApplicationController
      def send_message
        # Add logic to handle the WhatsApp message sending
        render json: { message: 'WhatsApp message sent successfully' }, status: :ok
      end
    end
  end
end