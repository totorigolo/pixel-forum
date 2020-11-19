
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

export function getUserToken(): string {
  const user_token_meta: HTMLMetaElement = document.querySelector("meta[name=\"websocket_user_token\"]");
  return user_token_meta && user_token_meta.content || null;
}
