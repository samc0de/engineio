# Engine.IO Client Library for Nim

This is a library for connecting to and communicating with an Engine.IO server using Nim. It provides a simple interface for sending and receiving messages over a WebSocket connection.

## Installation

To install the library, run the following command:

```bash
nimble install engineio
```

## Usage

To use the library, import it and create a new EngineIoClient object:

```
import engineio

let client = engineio.new("ws://localhost:3000")
```

You can then use the sendMessage and onEvent procedures to send messages to and receive messages from the server:

```
# Send a message to the server
engineio.sendMessage(client, "hello", %*{"name": "John"})

# Set up an event handler for the "greeting" event
engineio.onEvent(client, "greeting", (data: JsonNode) =>
  echo "Received greeting from the server: ", data.getStr()
)
```

## API
`new(url: string, asyncHandlers = true, threadHandlers = false): EngineIoClient`
Creates a new EngineIoClient object and connects to the specified Engine.IO server.

`sendMessage(client: EngineIoClient, event: string, data: JsonNode)`
Sends a message to the server.

`onEvent(client: EngineIoClient, event: string, handler: proc(data: JsonNode))`
Registers a handler for the specified event.

## License


