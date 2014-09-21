require "spec_helper"

describe Lita::Adapters::Slack, lita: true do
  before do
    Lita.configure do |config|
      config.adapter.incoming_token = 'aN1NvAlIdDuMmYt0k3n'
      config.adapter.team_domain = 'example'
      config.adapter.username = 'lita'
      config.adapter.add_mention = true
    end
  end

  subject { described_class.new(robot) }
  let(:robot) { double("Lita::Robot") }

  it "registers with Lita" do
    expect(Lita.adapters[:slack]).to eql(described_class)
  end

  it "fails without valid config: incoming_token and team_domain" do
    Lita.clear_config
    expect(Lita.logger).to receive(:fatal).with(/incoming_token, team_domain/)
    expect { subject }.to raise_error(SystemExit)
  end

  describe "#send_messages" do
    let(:target)    { double("Lita::Source", room: "CR00M1D") }
    let(:user)      { double("Lita::User", id: "UM3NT10N") }
    let(:connector) { double }

    before { subject.connector = connector }

    context 'building payload' do
      let(:message_factory) { double }
      before { subject.message_factory = message_factory }

      it "builds a payload" do
        json = double
        expect(message_factory).to receive(:call).with(target: target, strings: ['Hello!'], username: 'lita', add_mention: true).and_return(json)
        expect(connector).to receive(:send_messages).with(json)

        subject.send_messages(target, ["Hello!"])
      end
    end

    it "sends JSON payload via HTTP POST to Slack channel" do
      allow(target).to receive(:user) { nil }
      payload = {'channel' => target.room, 'username' => Lita.config.adapter.username, 'text' => 'Hello!'}

      expect(connector).to receive(:send_messages).with(payload.to_json)
      subject.send_messages(target, ["Hello!"])
    end

    context 'with mention' do
      before { allow(target).to receive(:user) { user } }

      it "sends message with mention if user info is provided" do
        text = "<@#{user.id}> Hello!"
        payload = {'channel' => target.room, 'username' => Lita.config.adapter.username, 'text' => text}

        expect(connector).to receive(:send_messages).with(payload.to_json)
        subject.send_messages(target, ["Hello!"])
      end
    end

    context 'without channel' do
      let(:target) { double("Lita::Source", user: user) }
      before { allow(target).to receive(:room) { nil } }

      it "proceeds but logs WARN when directed to an user without channel(room) info" do
        text = "<@#{user.id}> Hello!"
        payload = {'channel' => nil, 'username' => Lita.config.adapter.username, 'text' => text}

        expect(connector).to receive(:send_messages).with(payload.to_json)
        expect(Lita.logger).to receive(:warn).with(/channel_id not specified/)
        subject.send_messages(target, ["Hello!"])
      end
    end
  end
end
