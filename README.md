
# Kilo Client

A ruby client for the Kilo message queue system.

## Installation

### Gemfile

```ruby
gem 'kilo_client'
```

### Elsewhere

```bash
sudo gem install kilo_client
```

## Usage

### Initialization

```ruby
require 'kilo/client'

kilo = Kilo::Client.new(
  hostname: ENV['KILO_HOSTNAME'],
  vhost:    ENV['KILO_VHOST'],
  username: ENV['KILO_USERNAME'],
  password: ENV['KILO_PASSWORD']
)
```

### Publish

*Signature:* `publish(<channel>, <message>)`

Send the message to a channel. It will be received by the first consumer which requests the message.

```ruby
kilo.publish('some.channel.name', 'Hello, World!')
```
###

### Broadcast

*Signature:* `broadcast(<channel>, <message>)`

Send the message to a channel. It will be received by all connected consumers. The message will not be available to consumers who connect after the broadcast has already finished.

```ruby
kilo.broadcast('some.topic.name', 'Hello, World!')
```

### Subscribe

*Signature:* `subscribe(<channel>, &block(metadata, message_body))`



