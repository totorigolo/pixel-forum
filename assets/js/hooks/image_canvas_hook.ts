import { HookInterface } from "../phoenix_types";
import { getUserToken } from "../utils";
import { ImageSocket } from "../image_socket";

export interface CustomWindow extends Window {
  imageSocket: ImageSocket;
}
declare let window: CustomWindow;

export const image_canvas_hook: HookInterface = {
  mounted() {
    const lobby_id: string = this.el.dataset.lobbyId;

    this.beforeDestroy();

    window.imageSocket = new ImageSocket(getUserToken(), document.querySelector("#image-canvas"));
    window.imageSocket.connectToLobby(lobby_id);
  },

  updated() {
    const lobby_id: string = this.el.dataset.lobbyId;
    window.imageSocket.connectToLobby(lobby_id);
  },

  beforeDestroy() {
    if (window.imageSocket) {
      window.imageSocket.disconnect();
      window.imageSocket = null;
    }
  },
};
