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
  LeavingChannel,
  WaitingForRetry,
}

const MAX_QUEUE_SIZE = 100;
const VERSION_DIFF_DISCONNECT_THRESHOLD = 1007;

export class ImageSocket {
  private lobby_id: LobbyId;
  private socket: AsyncSocket;
  private image_channel: AsyncChannel;
  private image_channel_presence: Presence; // TODO: Lobby presence instead
  private canvas: PixelCanvas;
  private state: ImageSocketState = ImageSocketState.Disconnected;
  private batch_queue: Array<Uint8Array> = [];
  private last_batch_version: number = undefined;

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
      decode: (packed_payload: unknown, callback: <T>(decoded: T) => void) => {
        const decoded: PhxMessage = msgpack.decode(new Uint8Array(packed_payload as ArrayBuffer)) as PhxMessage;
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

    this.batch_queue = [];
    this.last_batch_version = undefined;

    this.image_channel = this.socket.channel(`image:${this.lobby_id}`, {});
    this.image_channel.on("pixel_batch", this.onReceiveBatch.bind(this));
    this.image_channel.on("presence", this.onPresence.bind(this));

    this.image_channel_presence = new Presence(this.image_channel.sync_channel());
    this.image_channel_presence.onSync(this.renderOnlineUsers.bind(this));

    await this.image_channel.join();
    console.log(`Joined successfully: ${lobby_id}`);

    try {
      await this.canvas.drawImage(`/lobby/${this.lobby_id}/image`);
      await this.handleQueuedBatches();

      this.state = ImageSocketState.JoinedChannel;
    } catch (error) {
      console.error("Failed to load lobby image: ", error);
      await this.retryConnect(this.lobby_id);
    }
  }

  public async leaveLobby(): Promise<void> {
    this.state = ImageSocketState.LeavingChannel;
    this.image_channel_presence = null;
    await this.image_channel.leave();
    this.state = ImageSocketState.Connected;
  }

  public async retryConnect(lobby_id: string): Promise<void> {
    if (this.state == ImageSocketState.WaitingForRetry) {
      return;
    } else if (this.state == ImageSocketState.JoinedChannel || this.state == ImageSocketState.JoiningChannel) {
      await this.leaveLobby();
    } else {
      console.warn(`Not supposed to retry connecting in state: ${ImageSocketState[this.state]}. Ignoring.`);
    }
    this.state = ImageSocketState.WaitingForRetry;

    // Wait some time before retrying.
    await new Promise(resolve => setTimeout(resolve, 3000));

    await this.connectToLobby(lobby_id);
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

  private async onReceiveBatch(payload: { d: Uint8Array }): Promise<void> {
    const batch_payload: Uint8Array = payload.d;
    if (this.state == ImageSocketState.JoinedChannel) {
      // The channel has been successfully joined, process the incoming batch.
      await this.handleBatch(batch_payload);
    } else if (this.state == ImageSocketState.WaitingForRetry) {
      // We are waiting to retry connecting to the channel, so just ignore the batch.
      console.info("Received a batch while in WaitingForRetry state."); // TODO: remove this log
      return;
    } else if (this.batch_queue.length > MAX_QUEUE_SIZE) {
      // The batch queue is too long, the client may have difficulties following up, so let's try again later.
      console.error(`Timed out joining the image channel (queue size exceeded: ${this.batch_queue.length} > ${MAX_QUEUE_SIZE}).`);
      await this.retryConnect(this.lobby_id);
    } else {
      // Received a payload, but we are still not fully connected, so we queue it for later.
      this.queueBatch(batch_payload);
    }
  }

  private async handleBatch(batch_payload: Uint8Array): Promise<void> {
    const type = batch_payload[0];
    if (type == 10) {
      await this.handlePixelBatch(batch_payload);
    } else {
      console.error(`Unknown batch type: "${type}".`);
    }
  }

  private async handleQueuedBatches(): Promise<void> {
    if (this.state != ImageSocketState.Connected) return;
    if (this.batch_queue.length == 0) return;
    console.log(`Handling ${this.batch_queue.length} queued batches.`);

    for (const batch_payload of this.batch_queue) {
      await this.handleBatch(batch_payload);
    }
    this.batch_queue = [];
  }

  private async handlePixelBatch(batch_payload: Uint8Array): Promise<void> {
    const binary_view = new DataView(batch_payload.buffer, batch_payload.byteOffset, batch_payload.byteLength);

    const start_version = getUint40(binary_view, 1);
    const nb_changes = (binary_view.byteLength - 6) / (2 * 2 + 3 * 1); // 2 16-bit coordinates, 3 8-bit color components

    if (this.last_batch_version != undefined) {
      const diff = start_version - this.last_batch_version;
      if (diff == 0) { /* no problem */ }
      else if (diff < VERSION_DIFF_DISCONNECT_THRESHOLD) {
        console.error(`Missed some batches (diff = ${diff}).`);
      } else {
        console.error(`Missed too many batches, disconnecting (diff = ${diff}).`);
        await this.retryConnect(this.lobby_id);
        return;
      }
    }
    this.last_batch_version = start_version + nb_changes;

    this.drawPixelBatch(nb_changes, new DataView(binary_view.buffer, batch_payload.byteOffset + 6, batch_payload.byteLength - 6));
  }

  private drawPixelBatch(nb_changes: number, payload: DataView): void {
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
