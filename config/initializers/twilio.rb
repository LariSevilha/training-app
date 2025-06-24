Rails.application.configure do
    config.after_initialize do
      # Verificar se as variáveis de ambiente estão configuradas
      required_vars = %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_WHATSAPP_NUMBER]
      missing_vars = required_vars.select { |var| ENV[var].blank? }
      
      if missing_vars.any?
        Rails.logger.warn "⚠️  Missing Twilio environment variables: #{missing_vars.join(', ')}"
        Rails.logger.warn "WhatsApp functionality will be disabled"
      else
        Rails.logger.info "✅ Twilio WhatsApp configured successfully"
        Rails.logger.info "📱 WhatsApp Number: #{ENV['TWILIO_WHATSAPP_NUMBER']}"
      end
    end
  end