import { Presence } from "phoenix";
import { AsyncChannel } from "./phoenix/async_channel";
import { AsyncSocket } from "./phoenix/async_socket";
import msgpack from "./msgpack";
import { PixelCanvas, Point, Color } from "./canvas";
import { getUint40 } from "./utils";
import { PhxMessage } from "./phoenix/types";

export type LobbyId = string;
export { Point, Color } from "./canvas";

enum ImageSocketState {
  Disconnected,
  Connected,
  JoiningChannel,
  JoinedChannel,
  FailedJoiningChannel,
  LeavingChannel,
}

const MAX_QUEUE_SIZE = 20;

export class ImageSocket {
  private lobby_id: LobbyId;
  private socket: AsyncSocket;
  private image_channel: AsyncChannel;
  private image_channel_presence: Presence; // TODO: Lobby presence instead
  private canvas: PixelCanvas;
  private state: ImageSocketState = ImageSocketState.Disconnected;
  private batch_queue: Array<Uint8Array> = [];

  constructor(user_token: string, image_canvas: HTMLCanvasElement) {
    this.socket = ImageSocket.createSocket(user_token);
    this.canvas = new PixelCanvas(image_canvas);

    this.socket.connect();
    this.state = ImageSocketState.Connected;
  }

  private static createSocket(user_token: string): AsyncSocket {
    return new AsyncSocket("/msgpack-socket", {
      params: { user_token: user_token },
      // logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data),
      decode: (packed_payload: string, callback: <T>(decoded: T) => void) => {
        const decoded: PhxMessage = msgpack.decode(new Uint8Array(packed_payload as unknown as ArrayBuffer)) as PhxMessage;
        const [join_ref, ref, topic, event, payload] = decoded;
        return callback({ join_ref, ref, topic, event, payload });
      },
    });
  }

  public async disconnect(): Promise<void> {
    this.state = ImageSocketState.Disconnected;
    await this.socket.disconnect();
  }

  public async connectToLobby(lobby_id: string): Promise<void> {
    console.log(`Connecting to lobby: ${lobby_id}`);
    this.state = ImageSocketState.JoiningChannel;

    this.lobby_id = lobby_id;

    if (this.image_channel) {
      await this.image_channel.leave();
      this.image_channel = null;
    }

    this.image_channel = this.socket.channel(`image:${this.lobby_id}`, {});
    this.image_channel.on("pixel_batch", this.onReceiveBatch.bind(this));
    this.image_channel.on("presence", this.onPresence.bind(this));

    this.image_channel_presence = new Presence(this.image_channel.sync_channel());
    this.image_channel_presence.onSync(this.renderOnlineUsers.bind(this));

    await this.image_channel.join();
    console.log(`Joined successfully: ${lobby_id}`);

    await this.loadImage();
    this.handleQueuedBatches();
    this.state = ImageSocketState.JoinedChannel;
  }

  public async leaveLobby(): Promise<void> {
    this.state = ImageSocketState.LeavingChannel;
    this.image_channel_presence = null;
    await this.image_channel.leave();
    this.state = ImageSocketState.Connected;
  }

  // public sendChangePixelRequest(point: Point, color: Color): void {
  //   this.image_channel.push("change_pixel", {
  //     x: point.x,
  //     y: point.y,
  //     r: color.r,
  //     g: color.g,
  //     b: color.b,
  //   })
  //     .receive("ok", () => console.log("Pixel changed successfully."))
  //     .receive("error", (response) => console.error("Failed to change pixel: ", response))
  //     .receive("timeout", (response) => console.error("Timed out changing pixel: ", response));
  // }

  private async loadImage() {
    try {
      await this.canvas.drawImage(`/lobby/${this.lobby_id}/image`);
    } catch (error) {
      console.error("Failed to load lobby image: ", error);
    }
  }

  private async onReceiveBatch(payload: { d: Uint8Array }): Promise<void> {
    const batch_payload: Uint8Array = payload.d;
    if (this.state == ImageSocketState.JoinedChannel) {
      this.handleBatch(batch_payload);
    } else {
      if (this.batch_queue.length > MAX_QUEUE_SIZE) {
        console.error("Timed out joining the image channel.");
        this.state = ImageSocketState.FailedJoiningChannel;
        await this.leaveLobby();
        return;
      }
      this.queueBatch(batch_payload);
    }
  }

  private handleBatch(batch_payload: Uint8Array): void {
    const type = batch_payload[0];
    if (type == 10) {
      this.handlePixelBatch(batch_payload);
    } else {
      console.error(`Unknown batch type: "${type}".`);
    }
  }

  private handleQueuedBatches(): void {
    if (this.batch_queue.length == 0) return;
    console.log(`Handling ${this.batch_queue.length} queued batches.`);

    for (const batch_payload of this.batch_queue) {
      this.handleBatch(batch_payload);
    }
    this.batch_queue = [];
  }

  private handlePixelBatch(batch_payload: Uint8Array): void {
    const binary_view = new DataView(batch_payload.buffer, batch_payload.byteOffset, batch_payload.byteLength);

    const start_version = getUint40(binary_view, 1);
    console.log(`Version: ${start_version}`);

    this.drawPixelBatch(new DataView(binary_view.buffer, batch_payload.byteOffset + 6, batch_payload.byteLength - 6));
  }

  private drawPixelBatch(payload: DataView): void {
    const nb_changes = payload.byteLength / (2 * 2 + 3 * 1); // 2 16-bit coordinates, 3 8-bit color components
    for (let i = 0, j = 0; i < nb_changes; i++, j += 7) {
      const point: Point = {
        x: payload.getUint16(j),
        y: payload.getUint16(j + 2),
      };
      const color: Color = {
        r: payload.getUint8(j + 4),
        g: payload.getUint8(j + 5),
        b: payload.getUint8(j + 6),
      };
      this.canvas.drawPixel(point, color);
    }
  }

  private queueBatch(batch_payload: Uint8Array): void {
    this.batch_queue.push(batch_payload);
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
