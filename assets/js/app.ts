/* Stylesheets */
import "../css/app.scss"; // Import SASS styles

/* Phoenix LiveView */
import "./live_view";

/* Actual app */
import { ImageSocket, Point, Color } from "./image_socket";
import { parseIntOrThrow, getUserToken } from "./utils";


// window.imageSocket = new ImageSocket(getUserToken(), document.querySelector("#image-canvas"));
// window.imageSocket.connectToLobby("1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2");

// const input_x: HTMLInputElement = document.querySelector("#input-x");
// const input_y: HTMLInputElement = document.querySelector("#input-y");
// const input_r: HTMLInputElement = document.querySelector("#input-r");
// const input_g: HTMLInputElement = document.querySelector("#input-g");
// const input_b: HTMLInputElement = document.querySelector("#input-b");

// const draw_btn = document.querySelector("#draw-btn");
// draw_btn.addEventListener("click", () => {
//   const point: Point = {
//     x: parseIntOrThrow(input_x.value, "x coordinate"),
//     y: parseIntOrThrow(input_y.value, "y coordinate"),
//   };
//   const color: Color = {
//     r: parseIntOrThrow(input_r.value, "red color component"),
//     g: parseIntOrThrow(input_g.value, "green color component"),
//     b: parseIntOrThrow(input_b.value, "blue color component"),
//   };
//   window.imageSocket.sendChangePixelRequest(point, color);
// });
