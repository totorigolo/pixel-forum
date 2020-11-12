import { Socket, Presence } from "phoenix"
import msgpack from "./msgpack"

let socket = new Socket("/msgpack-socket", {
  // logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data),
  decode: (rawPayload, callback) => {
    let decoded = msgpack.decode(new Uint8Array(rawPayload))
    let [join_ref, ref, topic, event, payload] = decoded
    return callback({ join_ref, ref, topic, event, payload })
  },
  params: {}
})

socket.connect()

let channel = socket.channel("image:lobby", {})
let presence = new Presence(channel)

//------------------------------------------------------------------------------
// Canvas

let imageCanvas = document.querySelector("#image-canvas")
let imageCanvasCtx = imageCanvas.getContext('2d')
imageCanvasCtx.imageSmoothingEnabled = false // disable anti-aliasing

function loadImage() {
  let image = new Image();
  image.onload = function () {
    createImageBitmap(image, 0, 0, 512, 512).then(bitmap => imageCanvasCtx.drawImage(bitmap, 0, 0))
  }
  image.src = '/api/image/0/0'
}

function drawPixel(x, y, r, g, b) {
  imageCanvasCtx.fillStyle = "rgb(" + r + "," + g + "," + b + ")"
  imageCanvasCtx.fillRect(x, y, 1, 1)
}

loadImage()

//------------------------------------------------------------------------------
// Pixel updates

let inputX = document.querySelector("#input-x")
let inputY = document.querySelector("#input-y")
let inputR = document.querySelector("#input-r")
let inputG = document.querySelector("#input-g")
let inputB = document.querySelector("#input-b")

let drawBtn = document.querySelector("#draw-btn")
drawBtn.addEventListener("click", event => {
  channel.push("change_pixel", {
    x: inputX.value,
    y: inputY.value,
    r: inputR.value,
    g: inputG.value,
    b: inputB.value,
  })
    .receive("ok", () => console.log("Pixel changed successfully."))
    .receive("error", () => console.error("Failed to change pixel."))
    .receive("timeout", () => console.log("Timed out changing pixel"))
})

channel.on("pc", payload => {
  drawPixel(payload.d[0], payload.d[1], payload.d[2], payload.d[3], payload.d[4])
})

//------------------------------------------------------------------------------
// Presence

let nbConnectedUsers = document.querySelector("#nb-connected-image")

function renderOnlineUsers(presence) {
  nbConnectedUsers.innerHTML = presence.list().length
}

channel.on("presence", payload => {
  nbConnectedUsers.innerHTML = JSON.stringify(payload.nb_connected, null, 2);
})
presence.onSync(() => renderOnlineUsers(presence))

//------------------------------------------------------------------------------

channel.join()
  .receive("ok", resp => { console.log("Joined successfully.") })
  .receive("error", resp => { console.error("Unable to join: ", resp) })

export default socket
