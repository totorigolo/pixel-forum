import { Socket, Presence } from "phoenix";
import msgpack from "./msgpack";

const user_token_meta: HTMLMetaElement = document.querySelector('meta[name="user_ws_token"]');
const user_token = user_token_meta && user_token_meta.content || null;

const socket = new Socket("/msgpack-socket", {
  params: { user_token: user_token },
  // logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data),
  decode: (packed_payload: string, callback: (decoded: any) => void) => {
    const decoded = msgpack.decode(new Uint8Array(packed_payload as unknown as ArrayBuffer));
    const [join_ref, ref, topic, event, payload] = decoded;
    return callback({ join_ref, ref, topic, event, payload });
  },
})

socket.connect()

const channel = socket.channel("image:1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2", {})
const presence = new Presence(channel)

//------------------------------------------------------------------------------
// Canvas

const imageCanvas: HTMLCanvasElement = document.querySelector("#image-canvas");
const imageCanvasCtx = imageCanvas.getContext('2d');
imageCanvasCtx.imageSmoothingEnabled = false; // disable anti-aliasing

function loadImage() {
  const image = new Image();
  image.onload = function () {
    createImageBitmap(image, 0, 0, 512, 512).then(bitmap => imageCanvasCtx.drawImage(bitmap, 0, 0));
  }
  image.src = '/lobby/1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2/image';
}

function drawPixel(x: number, y: number, r: number, g: number, b: number) {
  imageCanvasCtx.fillStyle = "rgb(" + r + "," + g + "," + b + ")";
  imageCanvasCtx.fillRect(x, y, 1, 1);
}

loadImage();

//------------------------------------------------------------------------------
// Pixel updates

const inputX: HTMLInputElement = document.querySelector("#input-x")
const inputY: HTMLInputElement = document.querySelector("#input-y")
const inputR: HTMLInputElement = document.querySelector("#input-r")
const inputG: HTMLInputElement = document.querySelector("#input-g")
const inputB: HTMLInputElement = document.querySelector("#input-b")

const drawBtn = document.querySelector("#draw-btn")
drawBtn.addEventListener("click", _event => {
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

function getUint40(dataView: DataView, byteOffset: number): number {
  const left = dataView.getUint8(byteOffset);
  const right = dataView.getUint32(byteOffset + 1);
  return 2 ** 32 * left + right;
}

channel.on("pixel_batch", payload => {
  const binary_view = new DataView(payload.d.buffer, payload.d.byteOffset, payload.d.byteLength)
  const start_version = getUint40(binary_view, 0)
  const nb_changes = (binary_view.byteLength - 5) / (2 * 2 + 3 * 1)
  for (let i = 0; i < nb_changes; i++) {
    const o = 5 + i * 7;
    const x = binary_view.getUint16(o)
    const y = binary_view.getUint16(o + 2)
    const r = binary_view.getUint8(o + 4)
    const g = binary_view.getUint8(o + 5)
    const b = binary_view.getUint8(o + 6)
    drawPixel(x, y, r, g, b)
  }
})

//------------------------------------------------------------------------------
// Presence

const nbConnectedUsers = document.querySelector("#nb-connected-image")

function renderOnlineUsers(presence: Presence) {
  nbConnectedUsers.innerHTML = presence.list().length.toString();
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
