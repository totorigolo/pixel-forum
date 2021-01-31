
export function parseIntOrThrow(s: string, what: string): number {
  const parsed = parseInt(s);
  if (isNaN(parsed)) {
    throw new Error(`Invalid ${what}: "${s}".`);
  }
  return parsed;
}

export function getUint40(dataView: DataView, byteOffset: number): number {
  const left = dataView.getUint8(byteOffset);
  const right = dataView.getUint32(byteOffset + 1);
  return 2 ** 32 * left + right;
}

export function wait(ms: number): () => Promise<unknown> {
  return () => new Promise(resolve => {
    setTimeout(resolve, ms);
  });
}
