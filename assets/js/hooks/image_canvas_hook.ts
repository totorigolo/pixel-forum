import { HookInterface } from "../phoenix/types";
import { ImageSocket } from "../image_socket";

interface CustomWindow extends Window {
  imageSocket: ImageSocket;
}
declare let window: CustomWindow;

export const image_canvas_hook: HookInterface = {
  mounted() {
    const lobby_id: string = this.el.dataset.lobbyId;
    void Promise.all([connectToLobby(lobby_id)]);
  },

  updated() {
    const lobby_id: string = this.el.dataset.lobbyId;
    void Promise.all([connectToLobby(lobby_id)]);
  },

  beforeDestroy() {
    void Promise.all([disconnectWindow()]);
  }
};

async function connectToLobby(lobby_id: string) {
  await disconnectWindow();

  window.imageSocket = new ImageSocket(document.querySelector("#image-canvas"));
  await window.imageSocket.connectToLobby(lobby_id);
}

async function disconnectWindow() {
  if (window.imageSocket) {
    await window.imageSocket.disconnect();
    window.imageSocket = null;
  }
}
