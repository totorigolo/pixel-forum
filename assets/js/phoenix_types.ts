
export type PhxMessage = [string, string, string, string, unknown];

export interface HookInterface {
  el?: HTMLElement;
  viewName?: string;
  pushEvent?(event: string, payload: object, onReply?: (reply: any, ref: number) => any): void;
  pushEventTo?(selectorOrTarget: any, event: string, payload: object, onReply?: (reply: any, ref: number) => any): void;
  handleEvent?(event: string, callback: (payload: object) => void): void;

  // callbacks
  mounted?: (this: HookInterface) => void;
  beforeUpdate?: (this: HookInterface) => void;
  updated?: (this: HookInterface) => void;
  beforeDestroy?: (this: HookInterface) => void;
  destroyed?: (this: HookInterface) => void;
  disconnected?: (this: HookInterface) => void;
  reconnected?: (this: HookInterface) => void;
}
