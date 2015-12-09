require 'spec_helper'

describe Kilo::Client do
  it 'can be initialized' do
    client = Kilo::Client.new
    expect(client).to be_a Kilo::Client
  end

  describe '#debug' do
    it 'defaults to false, but can be set to true' do
      client = Kilo::Client.new
      expect(client.debug).to be_falsey
      client.debug = true
      expect(client.debug).to be_truthy
      client.debug = false
      expect(client.debug).to be_falsey
    end
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
          expect(@client.authenticated?).to be_falsey
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
        it 'sets #authenticated? to true' do
          expect(@client.authenticated?).to be_truthy
        end
      end
      context 'fails' do
        before do
          expect(@client.authenticated?).to be_falsey
          expect(@client.class).to receive(:post).with('/api/auth', hash_including({
            body: @params.slice(:username, :password)
          })) do
            response = double('response')
              expect(response).to receive(:code){ 401 }
              expect(response).not_to receive(:get_fields).with('Set-Cookie')
            response
          end
        end
        it 'raises an error' do
          expect{@client.authenticate!}.to raise_error Kilo::AuthError
        end
      end
    end
  end

  describe '#publish(channel, message)' do
    before do
      @params = {
        username: 'kilo',
        password: 'password',
        vhost:    'default',
        hostname: 'localhost',
      }
      @client = Kilo::Client.new(@params)
    end
    context 'when the client' do
      context 'has not yet authenticated' do
        it 'raises an error' do
          expect{@client.publish('foo', 'bar')}.to raise_error Kilo::NotYetAuthenticatedError
        end
      end
      context 'has already authenticated' do
        before do
          expect(@client).to receive(:authenticated?){ true }
        end
        context 'when publishing' do
          context 'succeeds' do
            before do
              @channel = SecureRandom.hex(8)
              @message = SecureRandom.uuid
              publish_uri = "/api/#{@client.vhost}/channels/#{@channel}/publish"
              expect(@client.class).to receive(:post).with(publish_uri, hash_including({
                  body: {messages: [@message]}
                })
              ) do
                response = double('response')
                  expect(response).to receive(:code){ 200 }
                  expect(response).not_to receive(:get_fields).with('Set-Cookie')
                  expect(response).to receive(:body) {
                    {
                      success: true,
                      published: 1
                    }.to_json
                  }
                response
              end
              @result = @client.publish(@channel, @message)
            end
            it 'returns success:true' do
              expect(@result.success).to be_truthy
            end
            it 'returns the number of messages published' do
              expect(@result.published).to eq 1
            end
          end
          context 'fails' do
            context 'because of bad parameters' do
              before do
                @channel = SecureRandom.hex(8)
                @message = SecureRandom.uuid
                publish_uri = "/api/#{@client.vhost}/channels/#{@channel}/publish"
                expect(@client.class).to receive(:post).with(publish_uri, hash_including({
                    body: {messages: [@message]}
                  })
                ) do
                  response = double('response')
                    expect(response).to receive(:code){ 400 }
                    expect(response).not_to receive(:get_fields).with('Set-Cookie')
                    expect(response).to receive(:body) {
                      {
                        success: false,
                        errors: ["test error"]
                      }.to_json
                    }
                  response
                end
              end
              it 'raises an error' do
                expect{@client.publish(@channel, @message)}.to raise_error Kilo::PublishError
              end
            end
            context 'because authentication failed' do
              before do
                @channel = SecureRandom.hex(8)
                @message = SecureRandom.uuid
                publish_uri = "/api/#{@client.vhost}/channels/#{@channel}/publish"
                expect(@client.class).to receive(:post).with(publish_uri, hash_including({
                    body: {messages: [@message]}
                  })
                ) do
                  response = double('response')
                    expect(response).to receive(:code){ 401 }
                    expect(response).not_to receive(:get_fields).with('Set-Cookie')
                    expect(response).to receive(:body) {
                      'Not Authorized'
                    }
                  response
                end
              end
              it 'raises an error' do
                expect{@client.publish(@channel, @message)}.to raise_error Kilo::AuthError
              end
            end
          end
        end
      end
    end
  end

  describe '#broadcast(channel, message)' do
  end
end
