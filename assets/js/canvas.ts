
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

export class Error {
  constructor(
    public message: string,
    public reason?: string | Event | unknown,
  ) { }
}

export class PixelCanvas {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = this.canvas.getContext("2d");
  }

  public async drawImage(url: string): Promise<void> {
    const image_promise: Promise<ImageBitmapSource> = new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = (error) => reject(new Error(`Could not draw: ${url}`, error));
      image.src = url;
    });

    const loaded_image = await image_promise;
    const bitmap = await createImageBitmap(loaded_image, 0, 0, 512, 512);
    this.ctx.drawImage(bitmap, 0, 0);
  }

  public drawPixel(point: Point, color: Color | string): void {
    this.ctx.fillStyle = toRgbString(color);
    this.ctx.fillRect(point.x, point.y, 1, 1);
  }
}
