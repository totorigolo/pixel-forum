import { Socket, Presence } from "phoenix";
import msgpack from "./msgpack";
import * as canvas from "./canvas";

const user_token_meta: HTMLMetaElement = document.querySelector("meta[name=\"user_ws_token\"]");
const user_token = user_token_meta && user_token_meta.content || null;

const socket = new Socket("/msgpack-socket", {
  params: { user_token: user_token },
  // logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data),
  decode: (packed_payload: string, callback: <T>(decoded: T) => void) => {
    type PhxMessage = [string, string, string, string, unknown];

    const decoded: PhxMessage = msgpack.decode(new Uint8Array(packed_payload as unknown as ArrayBuffer)) as PhxMessage;
    const [join_ref, ref, topic, event, payload] = decoded;
    return callback({ join_ref, ref, topic, event, payload });
  },
});

socket.connect();

const channel = socket.channel("image:1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2", {});
const presence = new Presence(channel);

//------------------------------------------------------------------------------
// Canvas

const imageCanvas: HTMLCanvasElement = document.querySelector("#image-canvas");
const imageCanvasCtx = imageCanvas.getContext("2d");
imageCanvasCtx.imageSmoothingEnabled = false; // disable anti-aliasing

canvas.drawImage(imageCanvasCtx, "/lobby/1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2/image");

//------------------------------------------------------------------------------
// Pixel updates

const inputX: HTMLInputElement = document.querySelector("#input-x");
const inputY: HTMLInputElement = document.querySelector("#input-y");
const inputR: HTMLInputElement = document.querySelector("#input-r");
const inputG: HTMLInputElement = document.querySelector("#input-g");
const inputB: HTMLInputElement = document.querySelector("#input-b");

const drawBtn = document.querySelector("#draw-btn");
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
    .receive("timeout", () => console.log("Timed out changing pixel"));
});

function getUint40(dataView: DataView, byteOffset: number): number {
  const left = dataView.getUint8(byteOffset);
  const right = dataView.getUint32(byteOffset + 1);
  return 2 ** 32 * left + right;
}

channel.on("pixel_batch", (payload: { d: Uint8Array }) => {
  const binary_view = new DataView(payload.d.buffer, payload.d.byteOffset, payload.d.byteLength);
  const start_version = getUint40(binary_view, 0);
  const nb_changes = (binary_view.byteLength - 5) / (2 * 2 + 3 * 1);
  for (let i = 0; i < nb_changes; i++) {
    const o = 5 + i * 7;
    const point: canvas.Point = {
      x: binary_view.getUint16(o),
      y: binary_view.getUint16(o + 2),
    };
    const color: canvas.Color = {
      r: binary_view.getUint8(o + 4),
      g: binary_view.getUint8(o + 5),
      b: binary_view.getUint8(o + 6),
    };
    canvas.drawPixel(imageCanvasCtx, point, color);
  }
});

//------------------------------------------------------------------------------
// Presence

const nbConnectedUsers = document.querySelector("#nb-connected-image");

function renderOnlineUsers(presence: Presence) {
  nbConnectedUsers.innerHTML = presence.list().length.toString();
}

channel.on("presence", (payload: { nb_connected: number }) => {
  nbConnectedUsers.innerHTML = JSON.stringify(payload.nb_connected, null, 2);
});
presence.onSync(() => renderOnlineUsers(presence));

//------------------------------------------------------------------------------

channel.join()
  .receive("ok", () => console.log("Joined successfully."))
  .receive("error", resp => console.error("Unable to join: ", resp));

export default socket;
