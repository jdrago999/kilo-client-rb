require 'spec_helper'

describe Kilo::Client do
  it 'can be initialized' do
    client = Kilo::Client.new
    expect(client).to be_a Kilo::Client
  end

  describe '#authenticate!' do
    before do
      @params = {
        username: 'kilo',
        password: 'password',
        vhost:    'default',
        hostname: 'localhost',
      }
      @client = Kilo::Client.new(@params)
    end
    context 'when authentication' do
      context 'succeeds' do
        before do
          expect(@client.class).to receive(:post).with('/api/auth', {
            verify: false,
            body: @params.slice(:username, :password)
          }) do
            response = double('response')
              expect(response).to receive(:code){ 200 }
              expect(response).to receive(:get_fields).with('Set-Cookie'){
                ["_kilo_session=xxx-fake-session-xxx; path=/; HttpOnly"]
              }
            response
          end
          @result = @client.authenticate!
        end
        it 'saves the session cookie' do
          expect(@client.cookies).to eq ['_kilo_session=xxx-fake-session-xxx']
        end
        it 'returns true' do
          expect(@result).to be_truthy
        end
      end
      context 'fails' do
        it 'raises an error'
      end
    end
  end

  describe '#publish(channel, message)' do
    context 'when the client' do
      context 'has not yet authenticated' do
        it 'raises an error'
      end
      context 'has already authenticated' do
        it 'publishes the message to the channel'
      end
    end
  end

  describe '#broadcast(channel, message)' do
  end
end
