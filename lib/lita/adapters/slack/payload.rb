module Lita
  module Adapters
    class Slack < Adapter
      class Payload
        def self.to_json(*args)
          new(*args).to_json
        end

        def initialize(target:, strings:, username:, add_mention:false)
          @target      = target
          @strings     = strings
          @username    = username
          @add_mention = add_mention
        end

        def to_json
          build.to_json.tap do |json|
            Lita.logger.debug "Slack::payload size: #{json.size}"
          end
        end

        private
        attr_reader :target, :strings, :username, :add_mention

        def build
          {}.tap do |payload|
            payload['channel']  = channel_id
            payload['username'] = username
            payload['text']     = text
          end
        end

        def text
          text = strings.join("\n")

          if add_mention && target.user
            text.prepend "<@#{target.user.id}> "
          end

          text
        end

        def channel_id
          if target.room && !target.room.empty?
            target.room
          else
            Lita.logger.warn 'Slack::channel_id not specified'
            nil
          end
        end
      end
    end
  end
end
