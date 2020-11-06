import { Socket, Presence } from "phoenix"

let socket = new Socket("/socket", { params: {} })

socket.connect()

let channel = socket.channel("counter:lobby", {})
let presence = new Presence(channel)

let incrementInput = document.querySelector("#increment-value-input")
let counterValue = document.querySelector("#counter-value")
let nbConnectedUsers = document.querySelector("#nb-connected-counter")

incrementInput.addEventListener("keypress", event => {
  if (event.key === 'Enter') {
    channel.push("increment", { value: incrementInput.value })
    incrementInput.value = ""
  }
})

channel.on("new_value", payload => {
  counterValue.innerHTML = JSON.stringify(payload.value, null, 2);
})

channel.on("presence", payload => {
  nbConnectedUsers.innerHTML = JSON.stringify(payload.nb_connected, null, 2);
})

function renderOnlineUsers(presence) {
  nbConnectedUsers.innerHTML = presence.list().length
}

presence.onSync(() => renderOnlineUsers(presence))
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
