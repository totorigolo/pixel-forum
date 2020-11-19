
export type Point = {
  x: number;
  y: number;
};
export type Color = {
  r: number;
  g: number;
  b: number;
};

function toRgbString(color: Color | string): string {
  if (typeof color == "string") {
    return color;
  } else {
    return `rgb(${color.r},${color.g},${color.b})`;
  }
}

export class PixelCanvas {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = this.canvas.getContext("2d");
  }

  public drawImage(url: string): void {
    const image = new Image();
    image.onload = () => {
      createImageBitmap(image, 0, 0, 512, 512)
        .then(bitmap => this.ctx.drawImage(bitmap, 0, 0))
        .catch(reason => console.error("Failed to load lobby image: ", reason));
    };
    image.src = url;
  }

  public drawPixel(point: Point, color: Color | string): void {
    this.ctx.fillStyle = toRgbString(color);
    this.ctx.fillRect(point.x, point.y, 1, 1);
  }
}
