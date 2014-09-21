require 'lita'
require 'faraday'
require 'json'
require 'lita/adapters/slack/connector'
require 'lita/adapters/slack/payload'

module Lita
  module Adapters
    class Slack < Adapter
      # Required Lita config keys (via lita_config.rb)
      require_configs :incoming_token, :team_domain
      attr_writer :connector, :message_factory

      def initialize(robot)
        super
      end

      # Adapter main run loop
      def run
        Lita.logger.debug 'Slack::run started'
        sleep
      rescue Interrupt
        Lita.logger.info 'Slack::shutting down'
      end

      def send_messages(target, strings)
        payload = message_factory.call(target: target,
                                      strings: strings,
                                     username: config.username,
                                  add_mention: config.add_mention)

        Lita.logger.info "Slack::send_messages with payload: #{payload}"

        response = connector.send_messages(payload)
      end

      def set_topic(*)
        Lita.logger.info 'Slack::set_topic no implementation'
      end

      def shut_down
        Lita.logger.info 'Slack::shut_down no implementation'
      end

      private
      attr_reader :connector, :config

      def config
        Lita.config.adapter
      end

      def connector
        @connector ||= Connector.new(token: config.incoming_token,
                               team_domain: config.team_domain,
                              incoming_url: config.incoming_url)
      end

      def message_factory
        @message_factory ||= Payload.public_method(:to_json)
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
