import "phoenix_html";
import { Socket } from "phoenix";
import * as nProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";
import { image_canvas_hook } from "./hooks/image_canvas_hook";

const liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: document.querySelector("meta[name='csrf-token']").getAttribute("content"),
  },
  hooks: {
    ImageCanvas: image_canvas_hook,
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
