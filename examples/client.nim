# Create a new Socket.IO client
let client = newSocketIoClient("ws://localhost:3000")

# Start the message handling loop
run(client)

# Connect to the server
connect(client)

# Set up event handlers
onConnect(client, proc(data: JsonNode) {.async.} =
  echo "Connected to the server"
)
onDisconnect(client, proc(data: JsonNode) {.async.} =
  echo "Disconnected from the server"
)
onEvent(client, "customEvent", proc(data: JsonNode) {.async.} =
  echo "Received custom event: ", data.toJson()
)

# Send a custom event to the server
emitEvent(client, "customEvent", %*{"message": "Hello, world!"})

