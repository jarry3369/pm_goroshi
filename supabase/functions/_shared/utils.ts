type JsonLike = Record<string, unknown> | unknown[] | null;

function withJsonHeaders(init?: ResponseInit): ResponseInit {
  const baseHeaders: HeadersInit = { "Content-Type": "application/json" };
  if (!init) return { headers: baseHeaders };
  const mergedHeaders = new Headers(init.headers || {});

  if (!mergedHeaders.has("Content-Type")) {
    mergedHeaders.set("Content-Type", "application/json");
  }
  return { ...init, headers: mergedHeaders };
}

export function jsonOk(data: JsonLike = {}, init?: ResponseInit): Response {
  const body = JSON.stringify({
    ok: true,
    ...(typeof data === "object" && data !== null
      ? (data as object)
      : { data }),
  });
  return new Response(body, withJsonHeaders(init));
}

export function jsonErr(
  message: string,
  status: number = 500,
  extra?: JsonLike
): Response {
  const payload: Record<string, unknown> = { ok: false, error: message };
  if (extra && typeof extra === "object")
    Object.assign(payload, extra as object);
  return new Response(JSON.stringify(payload), withJsonHeaders({ status }));
}

export function methodNotAllowed(): Response {
  return jsonErr("method not allowed", 405);
}

export function badRequest(message: string): Response {
  return jsonErr(message, 400);
}

export function normalizePhone(raw: string) {
  const digits = (raw || "").replace(/[^0-9]/g, "");
  const dashed =
    digits.length === 11
      ? `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7)}`
      : digits;
  return { plain: digits, dashed };
}

export function logDebug(message: string, ...args: unknown[]) {
  try {
    console.log(`[Debug] ${message} `, ...args);
  } catch {
    //
  }
}
