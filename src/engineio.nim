import asyncdispatch, httpbeast, json, os, strformat, ws, tables, httpclient  # asyncnet,
import sugar, std/threadpool, std/oids

# Define a Socket.IO client type
type
  SocketIoClient* = object
    url: string
    socket: WebSocket
    eventHandlers: Table[string, proc(data: JsonNode)]
    messageHandlers: Table[string, proc(data: JsonNode)]
    asyncHandlers: bool
    threadHandlers: bool

 #  WebSocketClient = ref object
 #    url: string
 #    sock: AsyncSocket
 #    onConnect: proc()
 #    onDisconnect: proc()
 #    onError: proc(err: Exception)
 #    onMessage: proc(msg: string)


# Set up the client
proc new(url: string, asyncHandlers:bool = true, threadHandlers:bool = false, port:int=443): SocketIoClient =
  let sock = waitFor newWebSocket(url)
  result = SocketIoClient(
    url: url,
    socket: sock,
    eventHandlers: initTable[string, proc(data: JsonNode)](),
    messageHandlers: initTable[string, proc(data: JsonNode)](),
    asyncHandlers: asyncHandlers,
    threadHandlers: threadHandlers
  )

# proc newWebSocketClient*(url: string, onC: proc(s: string)=lambda(s: echo(s)), onD: proc(s: string)=lambda(s: echo(s)), onE: proc(s: string)=lambda(s: echo(s)), onM: proc(s: string)=lambda(s: echo(s)) ): WebSocketClient =
# proc newWebSocketClient*(url: string, onC: (s: string) => echo(s), onD: (s: string) =>  echo(s), onE: (s: string) => echo(s), onM: (s: string) => echo(s) ): WebSocketClient =
proc newSocketIoClient*(url: string, onC: proc = echo, onD: proc =  echo, onE: proc = echo, onM: proc = echo ): SocketIoClient =
  result = SocketIoClient(
  url: url,
  socket: waitFor newWebSocket(url),
  onConnect: onC,
  onDisconnect: onD,
  onError: onE,
  onMessage: onM)
  


# Define a function for sending messages to the server
proc sendMessage(client: SocketIoClient, event: string, data: JsonNode) {.async.} =
  # Encode the message as a JSON object
  let msg = %*{"event": event, "data": data}

  # Send the message over the WebSocket
  await client.socket.send($msg)


# Define a function for handling incoming messages
proc handleMessage(client: SocketIoClient, msg: JsonNode) {.async.} =
  # Determine the message type
  let msgType = msg["type"].getInt()

  # Handle the message based on its type
  case msgType:
    of 0,1:
      # Do nothing
      discard
    of 2:
      # Handle an event message
      let event = msg["event"].getStr()
      let data = msg["data"]

      # Check if the event has a registered handler
      if event in client.eventHandlers:
        # Execute the event handler
        if client.asyncHandlers:
           client.eventHandlers[event](data)
        elif client.threadHandlers:
          spawn client.eventHandlers[event](data)
        else:
          client.eventHandlers[event](data)
    of 3:
      # Handle an acknowledgement message
      let id = $msg["id"]  # .getInt()
      let data = msg["data"]

      # Check if the acknowledgement has a registered handler
      if id in client.messageHandlers:
        # Execute the acknowledgement handler
        if client.asyncHandlers:
          client.messageHandlers[id](data)
        elif client.threadHandlers:
          spawn client.messageHandlers[id](data)
        else:
          client.messageHandlers[id](data)
    of 4:
      # Handle an error message
      let data = msg["data"]
      echo "Received error message: ", $data
    else:
      echo "Received unexpected message type: ", msgType

# Define a function for running the client
proc run(client: SocketIoClient) {.async.} =
  # Listen for incoming messages on the WebSocket
  while true:
    let msg = await client.socket.receiveStrPacket()
    let msgJson = parseJson(msg)
    if msgJson == nil:
      echo "Received invalid message: ", msg
    else:
      # Pass the message to the handler function
      await handleMessage(client, msgJson)

# Define a function for connecting to the server
proc connect(client: SocketIoClient) {.async.} =
  # Send a "connect" message to the server
  await sendMessage(client, "connect", JsonNode())

# Define a function for disconnecting from the server
proc disconnect(client: SocketIoClient) {.async.} =
  # Send a "disconnect" message to the server
  await sendMessage(client, "disconnect", JsonNode())

# Define a function for handling "connect" events
proc onConnect(client: SocketIoClient, handler: proc) =
  # Register the event handler
  client.eventHandlers["connect"] = handler

# Define a function for handling "disconnect" events
proc onDisconnect(client: SocketIoClient, handler: proc) =
  # Register the event handler
  client.eventHandlers["disconnect"] = handler

# Define a function for handling "event" events
proc onEvent(client: SocketIoClient, event: string, handler: proc) =
  # Register the event handler
  client.eventHandlers[event] = handler

# Define a function for sending an "event" message to the server
proc emitEvent(client: SocketIoClient, event: string, data: JsonNode, ack: proc = nil) {.async.} =
  # Check if an acknowledgement handler was provided
  if ack != nil:
    # Generate a unique message ID
    let id = $genOid()

    # Register the acknowledgement handler
    client.messageHandlers[id] = ack

    # Send the "event" message with the message ID
    await sendMessage(client, "event", %*{"event": event, "data": data, "id": id})
  else:
    # Send the "event" message without a message ID
    await sendMessage(client, "event", %*{"event": event, "data": data})
