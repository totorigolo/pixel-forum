import "phoenix_html";
import { wait } from "./utils";
import { Socket } from "phoenix";
import * as nProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";
import { image_canvas_hook } from "./hooks/image_canvas_hook";
import { lobby_thumbnail_hook, thumbnail_refresher_hook } from "./hooks/lobby_thumbnail_hooks";

const liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: document.querySelector("meta[name='csrf-token']").getAttribute("content"),
  },
  hooks: {
    ImageCanvas: image_canvas_hook,
    LobbyThumbnail: lobby_thumbnail_hook,
    LobbyThumbnailRefresher: thumbnail_refresher_hook,
  }
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", () => nProgress.start());
window.addEventListener("phx:page-loading-stop", () => nProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

export interface LiveViewWindow extends Window {
  liveSocket: LiveSocket;
}
declare let window: LiveViewWindow;
window.liveSocket = liveSocket;

/**
 * If user doesn't request server long enough (few minutes), his session expires
 * and he has to re-login again. If user manages to request server before the
 * time has expired, his cookie is updated and the timer is reset.
 *
 * The problem is that almost the whole website uses LiveView, even for
 * navigation, which means that most of the requests go through WebSockets,
 * where you can't update cookies, and so the session inevitably expires, even
 * if user is actively using the website. More of that - it might expire during
 * an editing of a project, and user will be redirected, loosing all its
 * progress. What a shame!
 *
 * To work this around, we periodically ping the server via a regular AJAX
 * requests, which is noticed by the auth system which, in turn, resets the
 * cookie timer.
 */
function keepAlive() {
  void fetch("/keep-alive")
    .then(wait(2 * 60 * 1000 /* ms */)) // 2 minutes
    .then(keepAlive);
}
if (document.querySelector("meta[name='logged-in']") != null) keepAlive();
