import { HookInterface } from "../phoenix/types";

type LobbyId = string;

interface CustomWindow extends Window {
  thumbnails_elements: Map<LobbyId, HTMLImageElement>;
}
declare let window: CustomWindow;
window.thumbnails_elements = new Map<LobbyId, HTMLImageElement>();

export const lobby_thumbnail_hook: HookInterface = {
  mounted() {
    window.thumbnails_elements.set(this.el.dataset.lobbyId, this.el as HTMLImageElement);
  },

  updated() {
    // window.thumbnails_elements.set(this.el.dataset.lobbyId, this.el as HTMLImageElement);
    console.debug(this.el.dataset.lobbyId, " updated.");
  },

  destroyed() {
    window.thumbnails_elements.delete(this.el.dataset.lobbyId);
  },
};

export const thumbnail_refresher_hook: HookInterface = {
  mounted() {
    this.handleEvent("refresh_thumbnail", refreshThumbnail);
  },
};

type RefreshThumbnailMessage = {
  lobby_id: string,
  version: number,
  no_cache: boolean | null,
};

function refreshThumbnail(msg: RefreshThumbnailMessage) {
  const image_el = window.thumbnails_elements.get(msg.lobby_id);
  if (!image_el) {
    console.error(`Received refresh event for inexistent thumbnail: ${msg.lobby_id}.`);
    return;
  }
  const suffix = msg.no_cache ? `&t=${Date.now()}` : "";
  image_el.src = `/lobby/${msg.lobby_id}/image?v=${msg.version}${suffix}`;
}
