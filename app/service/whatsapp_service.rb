# app/services/whatsapp_service.rb
class WhatsappService
    def self.send_confirmation(user)
      return unless user.phone_number.present?
  
      message = "Olá, #{user.name}! Seu cadastro foi realizado com sucesso. Seu login: #{user.email}"
      # Exemplo: integração com Twilio ou WhatsApp Business API
      begin
        # Substitua pelo código da sua API de escolha
        # Exemplo com Twilio:
        # client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
        # client.messages.create(
        #   from: 'whatsapp:+14155238886', # Seu número WhatsApp
        #   to: "whatsapp:#{user.phone_number}",
        #   body: message
        # )
        Rails.logger.info("Mensagem WhatsApp enviada para #{user.phone_number}: #{message}")
      rescue StandardError => e
        Rails.logger.error("Erro ao enviar mensagem WhatsApp para #{user.phone_number}: #{e.message}")
      end
    end
  end