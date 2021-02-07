// From: https://nerds.stoiximan.gr/2016/11/23/binary-data-over-phoenix-sockets/

const formats = {
  positiveFixIntStart: 0x00,
  positiveFixIntEnd: 0x07F,
  fixMapStart: 0x80,
  fixMapEnd: 0x8F,
  fixArrStart: 0x90,
  fixArrEnd: 0x9F,
  fixStrStart: 0xA0,
  fixStrEnd: 0xBF,
  nil: 0xC0,
  none: 0xC1,
  bFalse: 0xC2,
  bTrue: 0xC3,
  bin8: 0xC4,
  bin16: 0xC5,
  bin32: 0xC6,
  ext8: 0xC7,
  ext16: 0xC8,
  ext32: 0xC9,
  float32: 0xCA,
  float64: 0xCB,
  uint8: 0xCC,
  uint16: 0xCD,
  uint32: 0xCE,
  uint64: 0xCF,
  int8: 0xD0,
  int16: 0xD1,
  int32: 0xD2,
  int64: 0xD3,
  fixExt1: 0xD4,
  fixExt2: 0xD5,
  fixExt4: 0xD6,
  fixExt8: 0xD7,
  fixExt16: 0xD8,
  str8: 0xD9,
  str16: 0xDA,
  str32: 0xDB,
  array16: 0xDC,
  array32: 0xDD,
  map16: 0xDE,
  map32: 0xDF,
  negativeFixIntStart: 0xE0,
  negativeFixIntEnd: 0xFF
};

/*
Decode returns two element [pos, data] arrays: index 0 holds the new position of
the parser, and index 1 contains the parsed data. We carry around the original
binary data array to avoid copying to new slices, while updating the parser
position and recursively calling decode until we've consumed all the buffer.
Missing from this implementation is extension support- add it if you need it.
*/
function decode(binaryData: Uint8Array, start: number): [number, unknown] {
  start = start || 0;
  const format = binaryData[start];

  if (format <= formats.positiveFixIntEnd) {
    return [start + 1, format - formats.positiveFixIntStart];
  }
  if (format <= formats.fixMapEnd) {
    const keyCount = format - formats.fixMapStart;
    return parseMap(binaryData, keyCount, start + 1);
  }
  if (format <= formats.fixArrEnd) {
    const len = format - formats.fixArrStart;
    return parseArray(binaryData, len, start + 1);
  }
  if (format <= formats.fixStrEnd) {
    const len = format - formats.fixStrStart;
    return parseUtf8String(binaryData, len, start + 1);
  }

  let pos, len;

  switch (format) {
    case formats.nil:
      return [start + 1, null];
    case formats.bFalse:
      return [start + 1, false];
    case formats.bTrue:
      return [start + 1, true];
    case formats.bin8:
      [pos, len] = parseUint(binaryData, 8, start + 1);
      return parseBinaryArray(binaryData, len, pos);
    case formats.bin16:
      [pos, len] = parseUint(binaryData, 16, start + 1);
      return parseBinaryArray(binaryData, len, pos);
    case formats.bin32:
      [pos, len] = parseUint(binaryData, 32, start + 1);
      return parseBinaryArray(binaryData, len, pos);
    case formats.float32:
      return parseFloat(binaryData, 32, start + 1);
    case formats.float64:
      return parseFloat(binaryData, 64, start + 1);
    case formats.uint8:
      return parseUint(binaryData, 8, start + 1);
    case formats.uint16:
      return parseUint(binaryData, 16, start + 1);
    case formats.uint32:
      return parseUint(binaryData, 32, start + 1);
    case formats.uint64:
      return parseUint(binaryData, 64, start + 1);
    case formats.int8:
      return parseInt(binaryData, 8, start + 1);
    case formats.int16:
      return parseInt(binaryData, 16, start + 1);
    case formats.int32:
      return parseInt(binaryData, 32, start + 1);
    case formats.int64:
      return parseInt(binaryData, 64, start + 1);
    case formats.str8:
      [pos, len] = parseUint(binaryData, 8, start + 1);
      return parseUtf8String(binaryData, len, pos);
    case formats.str16:
      [pos, len] = parseUint(binaryData, 16, start + 1);
      return parseUtf8String(binaryData, len, pos);
    case formats.str32:
      [pos, len] = parseUint(binaryData, 32, start + 1);
      return parseUtf8String(binaryData, len, pos);
    case formats.array16:
      [pos, len] = parseUint(binaryData, 16, start + 1);
      return parseArray(binaryData, len, pos);
    case formats.array32:
      [pos, len] = parseUint(binaryData, 32, start + 1);
      return parseArray(binaryData, len, pos);
    case formats.map16:
      [pos, len] = parseUint(binaryData, 16, start + 1);
      return parseMap(binaryData, len, pos);
    case formats.map32:
      [pos, len] = parseUint(binaryData, 32, start + 1);
      return parseMap(binaryData, len, pos);
  }

  if (format >= formats.negativeFixIntStart && format <= formats.negativeFixIntEnd) {
    return [start + 1, - (formats.negativeFixIntEnd - format + 1)];
  }

  throw new Error(`I don't know how to decode format [${format}]`);
}

function parseMap(binaryData: Uint8Array, keyCount: number, start: number): [number, Record<string, unknown>] {
  const ret: Record<string | number, unknown> = {};
  let pos = start;
  for (let i = 0; i < keyCount; i++) {
    const [keypos, key] = decode(binaryData, pos) as [number, string | number];
    pos = keypos;
    const [valpos, value] = decode(binaryData, pos);
    pos = valpos;
    ret[key] = value;
  }
  return [pos, ret];
}

function parseArray(binaryData: Uint8Array, length: number, start: number): [number, unknown[]] {
  const ret = [];
  let pos = start;
  for (let i = 0; i < length; i++) {
    const [newpos, data] = decode(binaryData, pos);
    pos = newpos;
    ret.push(data);
  }
  return [pos, ret];
}

function parseUint(binaryData: Uint8Array, length: number, start: number): [number, number] {
  let num = 0;
  let pos = start;
  let count = length;
  while (count > 0) {
    count -= 8;
    num += binaryData[pos] << count;
    pos++;
  }
  return [pos, num];
}

function parseInt(binaryData: Uint8Array, length: number, start: number): [number, number] {
  const [pos, unum] = parseUint(binaryData, length, start);
  const s = 64 - length;
  //https://github.com/inexorabletash/polyfill/blob/master/typedarray.js
  return [pos, (unum << s) >> s];
}

function parseBinaryArray(binaryData: Uint8Array, length: number, start: number): [number, Uint8Array] {
  const pos = start + length;
  if (binaryData.subarray) {
    return [pos, binaryData.subarray(start, pos)];
  } else {
    return [pos, binaryData.slice(start, pos)];
  }
}

function parseFloat(binaryData: Uint8Array, length: number, start: number): [number, number] {
  const bytecount = length / 8;
  const view = new DataView(new ArrayBuffer(length));
  for (let i = start; i < bytecount; i++) {
    view.setUint8(i - start, binaryData[i]);
  }
  const result = (length == 32) ? view.getFloat32(0, false) : view.getFloat64(0, false);
  return [start + bytecount, result];
}

function parseUtf8String(binaryData: Uint8Array, length: number, start: number): [number, string] {
  //from https://gist.github.com/boushley/5471599
  const result = [];
  let i = start;
  let c1 = 0;
  let c2 = 0;
  let c3 = 0;

  // If we have a BOM skip it
  if (length >= 3 && binaryData[i] === 0xef && binaryData[i + 1] === 0xbb && binaryData[i + 2] === 0xbf) {
    i += 3;
  }

  const mark = length + start;
  while (i < mark) {
    c1 = binaryData[i];
    if (c1 < 128) {
      result.push(String.fromCharCode(c1));
      i++;
    } else if (c1 > 191 && c1 < 224) {
      if (i + 1 >= binaryData.length) {
        throw "UTF-8 Decode failed. Two byte character was truncated.";
      }
      c2 = binaryData[i + 1];
      result.push(String.fromCharCode(((c1 & 31) << 6) | (c2 & 63)));
      i += 2;
    } else {
      if (i + 2 >= binaryData.length) {
        throw "UTF-8 Decode failed. Multi byte character was truncated.";
      }
      c2 = binaryData[i + 1];
      c3 = binaryData[i + 2];
      result.push(String.fromCharCode(((c1 & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63)));
      i += 3;
    }
  }
  return [mark, result.join('')];
}

const msgpack = {
  decode: (binaryArray: Uint8Array): unknown => decode(binaryArray, 0)[1],
};

export default msgpack;
