# OpenAI Configuration for RubyLLM
# 
# You can configure your OpenAI API key in one of two ways:
# 
# 1. Environment Variable (Recommended for production):
#    Set OPENAI_API_KEY in your environment
# 
# 2. Rails Credentials (Recommended for development):
#    Run: rails credentials:edit
#    Add:
#    openai:
#      api_key: your_api_key_here
#
# The SocialContentGenerationService will automatically pick up the key from either location.

# Validate that an API key is available
api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV['OPENAI_API_KEY']

if api_key.blank?
  Rails.logger.warn "OpenAI API key not configured. Set OPENAI_API_KEY environment variable or add to Rails credentials."
  puts "⚠️  OpenAI API key not found. Social content generation will use fallback content."
  puts "   To configure:"
  puts "   1. Set environment variable: export OPENAI_API_KEY='your-api-key'"
  puts "   2. Or add to credentials: rails credentials:edit"
else
  Rails.logger.info "OpenAI API key configured successfully"
  puts "✅ OpenAI API key configured for content generation"
end