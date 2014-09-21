module Lita
  module Adapters
    class Slack < Adapter
      class Connector
        attr_writer :request

        def initialize(token:, team_domain:, incoming_url:nil)
          @token        = token
          @team_domain  = team_domain
          @incoming_url = incoming_url
        end

        def send_messages(json)
          Lita.logger.debug 'Slack::send_messages started'

          response = request.post do |req|
            req.body = json
          end

          Lita.logger.debug 'Slack::send_messages ending'
          response.status
        end

        private
        attr_reader :token, :team_domain

        def request
          @request ||= Faraday.new(url: incoming_url) do |req|
            req.use Faraday::Request::UrlEncoded
            req.use Faraday::Adapter::NetHttp

            req.headers['Content-Type'] = 'application/json'
            req.params['token']         = token
          end
        end

        def incoming_url
          @incoming_url || "https://#{team_domain}.slack.com/services/hooks/incoming-webhook"
        end
      end
    end
  end
end
