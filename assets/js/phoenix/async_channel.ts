import { Channel } from "phoenix";


export class AsyncChannel {
  constructor(private channel: Channel) {}

  public sync_channel(): Channel {
    return this.channel;
  }

  async join<T>(timeout?: number): Promise<T> {
    return await new Promise((resolve, reject) => {
      this.channel.join(timeout)
        .receive("ok", (resp: T) => resolve(resp))
        .receive("error", resp => reject(resp))
        .receive("timeout", resp => reject(resp));
    });
  }

  async leave<T>(timeout?: number): Promise<T> {
    return new Promise((resolve, reject) => {
      this.channel.leave(timeout)
        .receive("ok", (resp: T) => resolve(resp))
        .receive("error", resp => reject(resp))
        .receive("timeout", resp => reject(resp));
    });
  }

  on<T>(event: string, callback: (response?: T) => void): number {
    return this.channel.on(event, callback);
  }

  off(event: string, ref?: number): void {
    return this.channel.off(event, ref);
  }

  async push<T>(event: string, payload: Record<string, unknown>, timeout?: number): Promise<T> {
    return new Promise((resolve, reject) => {
      this.channel.leave(timeout)
        .receive("ok", (resp: T) => resolve(resp))
        .receive("error", resp => reject(resp))
        .receive("timeout", resp => reject(resp));
    });
  }
}
