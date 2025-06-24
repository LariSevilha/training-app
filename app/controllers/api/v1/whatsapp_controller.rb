# app/controllers/api/v1/whatsapp_controller.rb
module Api
  module V1
    class WhatsappController < ApplicationController
      skip_before_action :authenticate_with_api_key, only: [:send_message]

      def send_message(phone_number: nil, message: nil)
        # Quando chamado internamente, não renderizar JSON
        return send_whatsapp_internal(phone_number, message) if phone_number && message

        # Quando chamado via API endpoint - fix parameter handling
        phone_number = params[:phone_number] || params[:phoneNumber]
        message = params[:message]

        unless phone_number && message
          render json: { error: 'phone_number and message are required' }, status: :bad_request
          return
        end

        result = send_whatsapp_internal(phone_number, message)
        
        if result[:success]
          render json: { message: 'WhatsApp message sent successfully', sid: result[:sid] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def send_whatsapp_internal(phone_number, message)
        # Verificar se as credenciais estão configuradas
        unless twilio_credentials_present?
          Rails.logger.error "Twilio credentials not configured"
          return { success: false, error: "Twilio credentials not configured" }
        end

        begin
          # Formatar o número de telefone
          formatted_number = format_phone_number(phone_number)
          
          Rails.logger.info "Sending WhatsApp with credentials - SID: #{ENV['TWILIO_ACCOUNT_SID']&.first(8)}..."
          
          client = Twilio::REST::Client.new(
            ENV['TWILIO_ACCOUNT_SID'],
            ENV['TWILIO_AUTH_TOKEN']
          )

          response = client.messages.create(
            from: "whatsapp:#{ENV['TWILIO_WHATSAPP_NUMBER']}",
            to: "whatsapp:#{formatted_number}",
            body: message
          )

          Rails.logger.info "WhatsApp message sent successfully to #{formatted_number}, SID: #{response.sid}"
          { success: true, sid: response.sid }
          
        rescue Twilio::REST::RestError => e
          Rails.logger.error "Twilio error: #{e.message}"
          { success: false, error: "Failed to send WhatsApp message: #{e.message}" }
        rescue StandardError => e
          Rails.logger.error "Unexpected error: #{e.message}"
          Rails.logger.error "Error backtrace: #{e.backtrace&.first(5)}"
          { success: false, error: "Unexpected error: #{e.message}" }
        end
      end

      def twilio_credentials_present?
        ENV['TWILIO_ACCOUNT_SID'].present? && 
        ENV['TWILIO_AUTH_TOKEN'].present? && 
        ENV['TWILIO_WHATSAPP_NUMBER'].present?
      end

      def format_phone_number(phone_number)
        # Remove todos os caracteres não numéricos
        clean_number = phone_number.gsub(/\D/, '')
        
        # Se não começar com código do país, adicionar +55 (Brasil)
        unless clean_number.start_with?('55')
          clean_number = "55#{clean_number}"
        end
        
        # Retornar com +
        "+#{clean_number}"
      end
    end
  end
end