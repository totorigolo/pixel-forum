import { Socket, Presence } from "phoenix"

let socket = new Socket("/socket", { params: {} })

socket.connect()

let channel = socket.channel("image:lobby", {})
let presence = new Presence(channel)

//------------------------------------------------------------------------------
// Canvas

let imageCanvas = document.querySelector("#image-canvas")
let imageCanvasCtx = imageCanvas.getContext('2d')

function loadImage() {
  let image = new Image();
  image.onload = function () {
    createImageBitmap(image, 0, 0, 512, 512).then(bitmap => imageCanvasCtx.drawImage(bitmap, 0, 0))
  }
  image.src = '/api/image/0'
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
})

channel.on("pixel_changed", payload => {
  drawPixel(
    payload.coordinate[0],
    payload.coordinate[1],
    payload.color[0],
    payload.color[1],
    payload.color[2],
  )
})

//------------------------------------------------------------------------------
// Presence

let nbConnectedUsers = document.querySelector("#nb-connected-image")

channel.on("presence", payload => {
  nbConnectedUsers.innerHTML = JSON.stringify(payload.nb_connected, null, 2);
})

function renderOnlineUsers(presence) {
  nbConnectedUsers.innerHTML = presence.list().length
}

presence.onSync(() => renderOnlineUsers(presence))

//------------------------------------------------------------------------------

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
