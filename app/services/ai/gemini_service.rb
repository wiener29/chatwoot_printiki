require 'net/http'
require 'uri'
require 'json'

module Ai
  class GeminiService
    def initialize(history = [], config = {})
      @history = history
      @api_key = InstallationConfig.find_by(name: 'GEMINI_API_KEY')&.value
      @model = config[:model].presence || 'gemini-1.5-pro'
      @system_instruction = config[:system_instruction].presence || "You are a helpful customer support agent. If you cannot solve the issue, reply with [ESCALATE]."
    end

    def generate_response
      return "Error: Gemini API Key not configured" if @api_key.blank?

      url = "https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent"
      uri = URI("#{url}?key=#{@api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10 # 10 seconds timeout

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = build_payload.to_json

      response = http.request(request)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "Gemini API Error: #{e.message}"
      "Error: Unable to process request at the moment."
    end

    private

    def build_payload
      {
        contents: @history.map { |msg| format_message(msg) },
        systemInstruction: {
          parts: [{ text: @system_instruction }]
        }
      }
    end

    def format_message(msg)
      role = msg[:role] == 'assistant' ? 'model' : 'user'
      {
        role: role,
        parts: [{ text: msg[:content] }]
      }
    end

    def parse_response(response)
      if response.code == '200'
        json = JSON.parse(response.body)
        json.dig('candidates', 0, 'content', 'parts', 0, 'text') || "Error: Empty response"
      else
        "Error: Gemini API returned #{response.code} - #{response.body}"
      end
    end
  end
end
