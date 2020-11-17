
export type Point = {
  x: number;
  y: number;
};
export type Color = {
  r: number;
  g: number;
  b: number;
};

export function drawImage(ctx: CanvasRenderingContext2D, url: string): void {
  const image = new Image();
  image.onload = function () {
    createImageBitmap(image, 0, 0, 512, 512)
      .then(bitmap => ctx.drawImage(bitmap, 0, 0))
      .catch(reason => console.error("Failed to load lobby image: ", reason));
  };
  image.src = url;
}

export function drawPixel(ctx: CanvasRenderingContext2D, point: Point, color: Color): void {
  ctx.fillStyle = `rgb(${color.r},${color.g},${color.b})`;
  ctx.fillRect(point.x, point.y, 1, 1);
}
