import { Socket, SocketConnectOption, ConnectionState, MessageRef } from "phoenix";
import { AsyncChannel } from "./async_channel";


export class AsyncSocket {
  private socket: Socket;

  constructor(endPoint: string, opts?: Partial<SocketConnectOption>) {
    this.socket = new Socket(endPoint, opts);
  }

  protocol(): string {
    return this.socket.protocol();
  }
  endPointURL(): string {
    return this.socket.endPointURL();
  }

  connect(): void {
    return this.socket.connect();
  }
  async disconnect(code?: number, reason?: string): Promise<void> {
    return new Promise((resolve) => {
      this.socket.disconnect(resolve, code, reason);
    });
  }
  connectionState(): ConnectionState {
    return this.socket.connectionState();
  }
  isConnected(): boolean {
    return this.socket.isConnected();
  }

  remove(channel: AsyncChannel): void {
    return this.socket.remove(channel.sync_channel());
  }
  channel(topic: string, chanParams?: Record<string, unknown>): AsyncChannel {
    const channel = this.socket.channel(topic, chanParams);
    return new AsyncChannel(channel);
  }
  push(data: Record<string, unknown>): void {
    return this.socket.push(data);
  }

  log(kind: string, message: string, data: unknown): void {
    return this.socket.log(kind, message, data);
  }
  hasLogger(): boolean {
    return this.socket.hasLogger();
  }

  onOpen(callback: (cb: unknown) => void): MessageRef {
    return this.socket.onOpen(callback);
  }
  onClose(callback: (cb: unknown) => void): MessageRef {
    return this.socket.onClose(callback);
  }
  onError(callback: (cb: unknown) => void): MessageRef {
    return this.socket.onError(callback);
  }
  onMessage(callback: (cb: unknown) => void): MessageRef {
    return this.socket.onMessage(callback);
  }

  makeRef(): MessageRef {
    return this.socket.makeRef();
  }
  off(refs: MessageRef[]): void {
    return this.socket.off(refs);
  }
}
