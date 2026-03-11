import {
  SAFETYREPORT_BASE_URL,
  SAFETYREPORT_HOST,
  SAFETYREPORT_REFERER,
  UA,
} from "./constants.ts";

const CRLF = "\r\n";
const HEADER_BODY_SEPARATOR = new Uint8Array([13, 10, 13, 10]);
const LINE_SEPARATOR = new Uint8Array([13, 10]);
const ASCII_DECODER = new TextDecoder("ascii");
const TEXT_ENCODER = new TextEncoder();
const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_RETRY_DELAY_MS = 250;
const READ_BUFFER_SIZE = 16_384;

export type CookieJar = Record<string, string>;
export type SafetyreportHttpMethod = "GET" | "POST";
export type SafetyreportErrorStage = "connect" | "write" | "read" | "parse";

export interface RawSafetyreportResponse {
  status: number;
  statusText: string;
  headers: Record<string, string[]>;
  bodyBytes: Uint8Array;
  bodyText: string;
}

export interface SafetyreportRequestOptions {
  method: SafetyreportHttpMethod;
  path: string;
  headers?: Record<string, string>;
  body?: string | URLSearchParams | Uint8Array;
  jar?: CookieJar;
  retries?: number;
  retryDelayMs?: number;
}

export class SafetyreportTransportError extends Error {
  stage: SafetyreportErrorStage;
  override cause?: unknown;

  constructor(stage: SafetyreportErrorStage, message: string, cause?: unknown) {
    super(message);
    this.name = "SafetyreportTransportError";
    this.stage = stage;
    this.cause = cause;
  }
}

export function createCookieJar(initial?: CookieJar): CookieJar {
  return { ...(initial ?? {}) };
}

export function buildCookieHeader(jar: CookieJar): string {
  return Object.entries(jar)
    .map(([name, value]) => `${name}=${value}`)
    .join("; ");
}

export function mergeSetCookieHeaders(
  jar: CookieJar,
  setCookieHeaders: string[] | undefined,
): CookieJar {
  if (!setCookieHeaders?.length) return jar;

  for (const headerValue of setCookieHeaders) {
    const firstPart = headerValue.split(";")[0]?.trim();
    if (!firstPart) continue;

    const separatorIndex = firstPart.indexOf("=");
    if (separatorIndex <= 0) continue;

    jar[firstPart.slice(0, separatorIndex).trim()] = firstPart
      .slice(separatorIndex + 1)
      .trim();
  }

  return jar;
}

export async function safetyreportRequest(
  options: SafetyreportRequestOptions,
): Promise<RawSafetyreportResponse> {
  const retries = options.retries ?? DEFAULT_MAX_RETRIES;
  const retryDelayMs = options.retryDelayMs ?? DEFAULT_RETRY_DELAY_MS;

  let lastError: unknown;
  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      return await executeRequest(options);
    } catch (error) {
      lastError = error;
      if (!(error instanceof SafetyreportTransportError) || attempt >= retries) {
        throw error;
      }

      await delay(retryDelayMs * attempt);
    }
  }

  throw lastError instanceof Error
    ? lastError
    : new SafetyreportTransportError(
        "connect",
        "unknown safetyreport transport error",
        lastError,
      );
}

function encodeBody(body: string | URLSearchParams | Uint8Array | undefined): {
  bytes: Uint8Array;
  isFormEncoded: boolean;
} {
  if (!body) return { bytes: new Uint8Array(), isFormEncoded: false };
  if (body instanceof Uint8Array) {
    return { bytes: body, isFormEncoded: false };
  }

  const text = body instanceof URLSearchParams ? body.toString() : body;
  return {
    bytes: TEXT_ENCODER.encode(text),
    isFormEncoded: body instanceof URLSearchParams,
  };
}

async function executeRequest(
  options: SafetyreportRequestOptions,
): Promise<RawSafetyreportResponse> {
  const url = new URL(options.path, SAFETYREPORT_BASE_URL);
  if (url.hostname !== SAFETYREPORT_HOST) {
    throw new SafetyreportTransportError(
      "connect",
      `unexpected host for safetyreport transport: ${url.hostname}`,
    );
  }

  const { bytes: bodyBytes, isFormEncoded } = encodeBody(options.body);
  const headers = new Headers({
    Accept: "*/*",
    "Accept-Encoding": "identity",
    "Accept-Language": "ko,ja;q=0.9,en;q=0.8,ko-KR;q=0.7",
    Connection: "close",
    Host: SAFETYREPORT_HOST,
    Referer: SAFETYREPORT_REFERER,
    "User-Agent": UA,
  });

  if (bodyBytes.byteLength > 0) {
    headers.set("Content-Length", String(bodyBytes.byteLength));
  }
  if (isFormEncoded) {
    headers.set(
      "Content-Type",
      "application/x-www-form-urlencoded; charset=UTF-8",
    );
  }
  if (options.jar && Object.keys(options.jar).length > 0) {
    headers.set("Cookie", buildCookieHeader(options.jar));
  }
  for (const [name, value] of Object.entries(options.headers ?? {})) {
    headers.set(name, value);
  }

  const requestLines = [`${options.method} ${url.pathname}${url.search} HTTP/1.1`];
  headers.forEach((value, name) => {
    requestLines.push(`${name}: ${value}`);
  });
  requestLines.push("", "");

  let conn: Deno.TlsConn | null = null;
  try {
    try {
      conn = await Deno.connectTls({ hostname: SAFETYREPORT_HOST, port: 443 });
    } catch (error) {
      throw new SafetyreportTransportError(
        "connect",
        `failed to connect to ${SAFETYREPORT_HOST}`,
        error,
      );
    }

    try {
      await writeAll(conn, TEXT_ENCODER.encode(requestLines.join(CRLF)));
      if (bodyBytes.byteLength > 0) {
        await writeAll(conn, bodyBytes);
      }
    } catch (error) {
      throw new SafetyreportTransportError(
        "write",
        `failed to write request to ${url.pathname}`,
        error,
      );
    }

    let responseBytes: Uint8Array;
    try {
      responseBytes = await readAll(conn);
    } catch (error) {
      throw new SafetyreportTransportError(
        "read",
        `failed to read response from ${url.pathname}`,
        error,
      );
    }

    return parseRawHttpResponse(responseBytes);
  } finally {
    conn?.close();
  }
}

interface ByteWriter {
  write(p: Uint8Array): Promise<number>;
}

interface ByteReader {
  read(p: Uint8Array): Promise<number | null>;
}

async function writeAll(writer: ByteWriter, bytes: Uint8Array): Promise<void> {
  let offset = 0;
  while (offset < bytes.byteLength) {
    offset += await writer.write(bytes.subarray(offset));
  }
}

async function readAll(reader: ByteReader): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let totalLength = 0;

  while (true) {
    const chunk = new Uint8Array(READ_BUFFER_SIZE);
    const readLength = await reader.read(chunk);
    if (readLength === null) break;

    const sliced = chunk.subarray(0, readLength);
    chunks.push(sliced);
    totalLength += sliced.byteLength;
  }

  const result = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.byteLength;
  }

  return result;
}

function parseRawHttpResponse(bytes: Uint8Array): RawSafetyreportResponse {
  const separatorIndex = findSequence(bytes, HEADER_BODY_SEPARATOR);
  if (separatorIndex === -1) {
    throw new SafetyreportTransportError(
      "parse",
      "failed to locate HTTP response header terminator",
    );
  }

  const headerText = ASCII_DECODER.decode(bytes.subarray(0, separatorIndex));
  const rawBody = bytes.subarray(separatorIndex + HEADER_BODY_SEPARATOR.length);
  const headerLines = headerText.split(CRLF);
  const statusLine = headerLines.shift();
  if (!statusLine) {
    throw new SafetyreportTransportError("parse", "missing HTTP status line");
  }

  const statusMatch = statusLine.match(/^HTTP\/\d\.\d\s+(\d{3})(?:\s+(.*))?$/);
  if (!statusMatch) {
    throw new SafetyreportTransportError(
      "parse",
      `invalid HTTP status line: ${statusLine}`,
    );
  }

  const headers: Record<string, string[]> = {};
  for (const line of headerLines) {
    const separator = line.indexOf(":");
    if (separator <= 0) continue;

    const name = line.slice(0, separator).trim().toLowerCase();
    const value = line.slice(separator + 1).trim();
    if (!headers[name]) headers[name] = [];
    headers[name].push(value);
  }

  const transferEncoding = headers["transfer-encoding"]
    ?.join(",")
    .toLowerCase();
  const contentLengthHeader = headers["content-length"]?.[0];

  let bodyBytes = rawBody;
  if (transferEncoding?.includes("chunked")) {
    bodyBytes = decodeChunkedBody(rawBody);
  } else if (contentLengthHeader) {
    const contentLength = Number(contentLengthHeader);
    if (!Number.isNaN(contentLength) && contentLength >= 0) {
      bodyBytes = rawBody.subarray(0, contentLength);
    }
  }

  return {
    status: Number(statusMatch[1]),
    statusText: statusMatch[2] ?? "",
    headers,
    bodyBytes,
    bodyText: decodeBody(bodyBytes, headers["content-type"]?.[0]),
  };
}

function decodeBody(bytes: Uint8Array, contentType?: string): string {
  const charset = contentType
    ?.split(";")
    .map((part) => part.trim())
    .find((part) => part.toLowerCase().startsWith("charset="))
    ?.split("=")[1]
    ?.trim()
    ?.toLowerCase();

  try {
    return new TextDecoder(charset || "utf-8").decode(bytes);
  } catch {
    return new TextDecoder().decode(bytes);
  }
}

function decodeChunkedBody(bytes: Uint8Array): Uint8Array {
  const chunks: Uint8Array[] = [];
  let totalLength = 0;
  let offset = 0;

  while (offset < bytes.byteLength) {
    const lineEnd = findSequence(bytes, LINE_SEPARATOR, offset);
    if (lineEnd === -1) {
      throw new SafetyreportTransportError(
        "parse",
        "invalid chunked response: missing size terminator",
      );
    }

    const sizeLine = ASCII_DECODER.decode(bytes.subarray(offset, lineEnd))
      .split(";")[0]
      ?.trim();
    const chunkSize = Number.parseInt(sizeLine, 16);
    if (Number.isNaN(chunkSize)) {
      throw new SafetyreportTransportError(
        "parse",
        `invalid chunk size: ${sizeLine}`,
      );
    }

    offset = lineEnd + LINE_SEPARATOR.length;
    if (chunkSize === 0) {
      return concatenate(chunks, totalLength);
    }

    const chunkEnd = offset + chunkSize;
    if (chunkEnd > bytes.byteLength) {
      throw new SafetyreportTransportError(
        "parse",
        "invalid chunked response: chunk exceeds body length",
      );
    }

    const chunk = bytes.subarray(offset, chunkEnd);
    chunks.push(chunk);
    totalLength += chunk.byteLength;
    offset = chunkEnd;

    if (offset + LINE_SEPARATOR.length > bytes.byteLength) {
      throw new SafetyreportTransportError(
        "parse",
        "invalid chunked response: missing chunk terminator",
      );
    }
    if (bytes[offset] !== 13 || bytes[offset + 1] !== 10) {
      throw new SafetyreportTransportError(
        "parse",
        "invalid chunked response: missing chunk terminator",
      );
    }
    offset += LINE_SEPARATOR.length;
  }

  throw new SafetyreportTransportError(
    "parse",
    "invalid chunked response: missing terminal chunk",
  );
}

function concatenate(chunks: Uint8Array[], totalLength: number): Uint8Array {
  const output = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of chunks) {
    output.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return output;
}

function findSequence(
  bytes: Uint8Array,
  sequence: Uint8Array,
  startIndex = 0,
): number {
  outer: for (
    let index = startIndex;
    index <= bytes.byteLength - sequence.byteLength;
    index += 1
  ) {
    for (let seqIndex = 0; seqIndex < sequence.byteLength; seqIndex += 1) {
      if (bytes[index + seqIndex] !== sequence[seqIndex]) continue outer;
    }
    return index;
  }

  return -1;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
