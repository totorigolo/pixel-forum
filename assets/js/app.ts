import "../css/app.scss"; // Import SASS styles

import "phoenix_html"; // Necessary for LiveViews

import { ImageSocket, Point, Color } from "./image_socket";
import { parseIntOrThrow, getUserToken } from "./utils";

const socket = new ImageSocket(getUserToken(), document.querySelector("#image-canvas"));
socket.connectToLobby("1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2");

const inputX: HTMLInputElement = document.querySelector("#input-x");
const inputY: HTMLInputElement = document.querySelector("#input-y");
const inputR: HTMLInputElement = document.querySelector("#input-r");
const inputG: HTMLInputElement = document.querySelector("#input-g");
const inputB: HTMLInputElement = document.querySelector("#input-b");

const drawBtn = document.querySelector("#draw-btn");
drawBtn.addEventListener("click", () => {
  const point: Point = {
    x: parseIntOrThrow(inputX.value, "x coordinate"),
    y: parseIntOrThrow(inputY.value, "y coordinate"),
  };
  const color: Color = {
    r: parseIntOrThrow(inputR.value, "red color component"),
    g: parseIntOrThrow(inputG.value, "green color component"),
    b: parseIntOrThrow(inputB.value, "blue color component"),
  };
  socket.sendChangePixelRequest(point, color);
});
