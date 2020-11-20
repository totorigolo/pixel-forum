import { Channel, Socket, Presence } from "phoenix";
import msgpack from "./msgpack";
import { PixelCanvas, Point, Color } from "./canvas";
import { getUint40 } from "./utils";
import { PhxMessage } from "./phoenix_types";

export type LobbyId = string;
export { Point, Color } from "./canvas";

export class ImageSocket {
  private lobby_id: LobbyId;
  private socket: Socket;
  private image_channel: Channel;
  private image_channel_presence: Presence; // TODO: Lobby presence instead
  private canvas: PixelCanvas;

  constructor(user_token: string, image_canvas: HTMLCanvasElement) {
    this.socket = ImageSocket.createSocket(user_token);
    this.canvas = new PixelCanvas(image_canvas);

    this.socket.connect();
  }

  private static createSocket(user_token: string): Socket {
    return new Socket("/msgpack-socket", {
      params: { user_token: user_token },
      // logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data),
      decode: (packed_payload: string, callback: <T>(decoded: T) => void) => {
        const decoded: PhxMessage = msgpack.decode(new Uint8Array(packed_payload as unknown as ArrayBuffer)) as PhxMessage;
        const [join_ref, ref, topic, event, payload] = decoded;
        return callback({ join_ref, ref, topic, event, payload });
      },
    });
  }

  public connectToLobby(lobby_id: string): void {
    console.log(`Connecting to lobby: ${lobby_id}`);

    this.lobby_id = lobby_id;

    if (this.image_channel) {
      this.image_channel.leave();
      this.image_channel = null;
    }

    this.image_channel = this.socket.channel(`image:${this.lobby_id}`, {});
    this.image_channel.on("pixel_batch", this.onReceivePixelBatch.bind(this));
    this.image_channel.on("presence", this.onPresence.bind(this));

    this.image_channel_presence = new Presence(this.image_channel);
    this.image_channel_presence.onSync(this.renderOnlineUsers.bind(this));

    this.image_channel.join()
      .receive("ok", () => console.log(`Joined successfully: ${lobby_id}`))
      .receive("error", resp => console.error(`Unable to join '${lobby_id}': `, resp));

    this.loadImage(); // TODO: move this call from there?
  }

  public disconnect(): void {
    this.socket.disconnect();
  }

  public sendChangePixelRequest(point: Point, color: Color): void {
    this.image_channel.push("change_pixel", {
      x: point.x,
      y: point.y,
      r: color.r,
      g: color.g,
      b: color.b,
    })
      .receive("ok", () => console.log("Pixel changed successfully."))
      .receive("error", (response) => console.error("Failed to change pixel: ", response))
      .receive("timeout", (response) => console.error("Timed out changing pixel: ", response));
  }

  private loadImage() {
    this.canvas.drawImage(`/lobby/${this.lobby_id}/image`);
  }

  private onReceivePixelBatch(payload: { d: Uint8Array }): void {
    const binary_view = new DataView(payload.d.buffer, payload.d.byteOffset, payload.d.byteLength);
    const start_version = getUint40(binary_view, 0);
    const nb_changes = (binary_view.byteLength - 5) / (2 * 2 + 3 * 1);
    for (let i = 0; i < nb_changes; i++) {
      const o = 5 + i * 7;
      const point: Point = {
        x: binary_view.getUint16(o),
        y: binary_view.getUint16(o + 2),
      };
      const color: Color = {
        r: binary_view.getUint8(o + 4),
        g: binary_view.getUint8(o + 5),
        b: binary_view.getUint8(o + 6),
      };
      this.canvas.drawPixel(point, color);
    }
  }

  private onPresence(payload: { nb_connected: number }): void {
    const nbConnectedUsers = document.querySelector("#nb-connected-image");
    nbConnectedUsers.innerHTML = JSON.stringify(payload.nb_connected, null, 2);
  }

  private renderOnlineUsers(): void {
    const nbConnectedUsers = document.querySelector("#nb-connected-image");
    nbConnectedUsers.innerHTML = this.image_channel_presence.list().length.toString();
  }
}
