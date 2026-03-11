import {
  SAFETYREPORT_BASE_URL,
  SAFETYREPORT_REFERER,
  UA,
} from "./constants.ts";
import {
  type CookieJar,
  type RawSafetyreportResponse,
  type SafetyreportErrorStage,
  createCookieJar,
  mergeSetCookieHeaders,
  safetyreportRequest,
  SafetyreportTransportError,
} from "./safetyreport_transport.ts";

export interface SafetyreportApiResult<T> {
  data: T;
  jar: CookieJar;
  response: RawSafetyreportResponse;
}

export interface RequestSmsPayload {
  SMS_CRTFC_ID?: string;
  result?: string;
  [key: string]: unknown;
}

export interface VerifySmsPayload {
  result?: string;
  [key: string]: unknown;
}

export interface SubmitSafeReportPayload {
  result?: string;
  STTEMNT_NO?: string;
  [key: string]: unknown;
}

export interface OAuthTokenPayload {
  access_token?: string;
  token_type?: string;
  [key: string]: unknown;
}

export interface MemberPayload {
  result?: {
    ACNT_ID?: string;
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

export interface SafeReportDetailAnswer {
  C_MANAGER_TYPE_NM?: string;
  C_MANAGE_ORG_NAME?: string;
  C_MANAGE_MAN?: string;
  C_MANAGE_MAN_PHONE?: string;
  C_MANAGE_MAN_EMAIL?: string;
  C_MANAGE_CONTENTS?: string;
  [key: string]: unknown;
}

export interface SafeReportDetailPayload {
  result?: {
    answers?: SafeReportDetailAnswer[];
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

export class SafetyreportApiError extends Error {
  step: string;
  status?: number;
  body?: unknown;
  override cause?: unknown;

  constructor(
    step: string,
    message: string,
    options?: { status?: number; body?: unknown; cause?: unknown },
  ) {
    super(message);
    this.name = "SafetyreportApiError";
    this.step = step;
    this.status = options?.status;
    this.body = options?.body;
    this.cause = options?.cause;
  }
}

export function newSafetyreportCookieJar(): CookieJar {
  return createCookieJar();
}

export async function requestSms(
  phone: string,
  jar: CookieJar = newSafetyreportCookieJar(),
): Promise<SafetyreportApiResult<RequestSmsPayload>> {
  const params = new URLSearchParams({
    MOBLPHON_NO: phone,
    SMS_CRTFC_SE: "01",
    SMS_CRTFC_TY: "01",
    CRTFC_TYPE: "M",
  });

  const response = await executeApiRequest("sms.request", () =>
    safetyreportRequest({
      method: "POST",
      path: "/api/v1/portal/common/sms",
      body: params,
      jar,
      headers: portalAjaxHeaders(),
    })
  );

  const data = parseJson<RequestSmsPayload>(response, "sms.request");
  if (response.status !== 200 || !data.SMS_CRTFC_ID) {
    throw new SafetyreportApiError("sms.request", "portal sms request failed", {
      status: response.status,
      body: data,
    });
  }

  syncCookies(jar, response);
  return { data, jar, response };
}

export async function verifySms(
  args: {
    smsRequestId: string;
    smsCode: string;
    phone: string;
    jar?: CookieJar;
  },
): Promise<SafetyreportApiResult<VerifySmsPayload>> {
  const jar = args.jar ?? newSafetyreportCookieJar();
  const params = new URLSearchParams({
    SMS_CRTFC_ID: args.smsRequestId,
    SMS_CRTFC_NO: args.smsCode,
    SMS_CRTFC_TY: "01",
    MOBLPHON_NO: args.phone,
  });

  const response = await executeApiRequest("sms.verify", () =>
    safetyreportRequest({
      method: "POST",
      path: "/api/v1/portal/common/sms/smsCrtfcTy",
      body: params,
      jar,
      headers: portalAjaxHeaders(),
    })
  );

  syncCookies(jar, response);
  const data = parseJson<VerifySmsPayload>(response, "sms.verify");
  if (response.status !== 200 || (data.result && data.result !== "success")) {
    throw new SafetyreportApiError(
      "sms.verify",
      "sms code authentication failed",
      {
        status: response.status,
        body: data,
      },
    );
  }

  return { data, jar, response };
}

export async function submitSafeReport(
  params: URLSearchParams,
  jar: CookieJar,
): Promise<SafetyreportApiResult<SubmitSafeReportPayload | null>> {
  const response = await executeApiRequest("report.submit", () =>
    safetyreportRequest({
      method: "POST",
      path: "/api/v1/portal/safereport/safereport",
      body: params,
      jar,
      headers: portalAjaxHeaders(),
    })
  );

  syncCookies(jar, response);
  const data = tryParseJson<SubmitSafeReportPayload>(response.bodyText);
  if (response.status !== 200 || (data?.result && data.result !== "success")) {
    throw new SafetyreportApiError("report.submit", "failed to submit safereport", {
      status: response.status,
      body: data ?? response.bodyText,
    });
  }

  return { data, jar, response };
}

export async function issuePortalToken(
  username: string,
  password: string,
  jar: CookieJar = newSafetyreportCookieJar(),
): Promise<SafetyreportApiResult<OAuthTokenPayload>> {
  const params = new URLSearchParams({
    client_id: "web",
    grant_type: "password",
    loginType: "2",
    username,
    password,
  });

  const response = await executeApiRequest("oauth.token", () =>
    safetyreportRequest({
      method: "POST",
      path: "/oauth/token",
      body: params,
      jar,
      headers: {
        Accept: "*/*",
        Origin: SAFETYREPORT_BASE_URL,
        Referer: SAFETYREPORT_REFERER,
        "User-Agent": UA,
      },
    })
  );

  syncCookies(jar, response);
  const data = parseJson<OAuthTokenPayload>(response, "oauth.token");
  if (response.status !== 200 || !data.access_token) {
    throw new SafetyreportApiError("oauth.token", "failed to get access token", {
      status: response.status,
      body: data,
    });
  }

  return { data, jar, response };
}

export async function fetchMemberAccount(
  args: {
    reportId: string;
    accessToken: string;
    jar?: CookieJar;
  },
): Promise<SafetyreportApiResult<MemberPayload>> {
  const jar = args.jar ?? newSafetyreportCookieJar();
  const encodedReportId = encodeURIComponent(args.reportId);
  const path =
    `/api/v1/common/auth/member/${encodedReportId}?loginid=${encodedReportId}&authnum=0`;
  const response = await executeApiRequest("member.fetch", () =>
    safetyreportRequest({
      method: "GET",
      path,
      jar,
      headers: authHeaders(args.accessToken),
    })
  );

  syncCookies(jar, response);
  const data = parseJson<MemberPayload>(response, "member.fetch");
  if (response.status !== 200 || !data.result?.ACNT_ID) {
    throw new SafetyreportApiError("member.fetch", "failed to get account id", {
      status: response.status,
      body: data,
    });
  }

  return { data, jar, response };
}

export async function fetchSafeReportDetails(
  args: {
    accountId: string;
    accessToken: string;
    jar?: CookieJar;
  },
): Promise<SafetyreportApiResult<SafeReportDetailPayload>> {
  const jar = args.jar ?? newSafetyreportCookieJar();
  const response = await executeApiRequest("report.detail", () =>
    safetyreportRequest({
      method: "GET",
      path: `/api/v1/portal/mypage/mysafereport/${encodeURIComponent(args.accountId)}`,
      jar,
      headers: authHeaders(args.accessToken),
    })
  );

  syncCookies(jar, response);
  const data = parseJson<SafeReportDetailPayload>(response, "report.detail");
  if (response.status !== 200) {
    throw new SafetyreportApiError(
      "report.detail",
      "failed to fetch report details",
      {
        status: response.status,
        body: data,
      },
    );
  }

  return { data, jar, response };
}

function portalAjaxHeaders(): Record<string, string> {
  return {
    Accept: "*/*",
    Origin: SAFETYREPORT_BASE_URL,
    Referer: SAFETYREPORT_REFERER,
    "User-Agent": UA,
    "X-Requested-With": "XMLHttpRequest",
  };
}

function authHeaders(accessToken: string): Record<string, string> {
  return {
    Accept: "*/*",
    Authorization: `Bearer ${accessToken}`,
    Origin: SAFETYREPORT_BASE_URL,
    Referer: SAFETYREPORT_REFERER,
    "User-Agent": UA,
    "X-Requested-With": "XMLHttpRequest",
  };
}

function syncCookies(jar: CookieJar, response: RawSafetyreportResponse): void {
  mergeSetCookieHeaders(jar, response.headers["set-cookie"]);
}

async function executeApiRequest(
  step: string,
  request: () => Promise<RawSafetyreportResponse>,
): Promise<RawSafetyreportResponse> {
  try {
    return await request();
  } catch (error) {
    if (error instanceof SafetyreportTransportError) {
      throw new SafetyreportApiError(
        step,
        `safetyreport transport failed during ${step}`,
        {
          body: buildTransportErrorBody(error.stage, error.message),
          cause: error,
        },
      );
    }

    throw error;
  }
}

function parseJson<T>(response: RawSafetyreportResponse, step: string): T {
  const parsed = tryParseJson<T>(response.bodyText);
  if (parsed === null) {
    throw new SafetyreportApiError(step, "failed to parse JSON response", {
      status: response.status,
      body: response.bodyText,
    });
  }

  return parsed;
}

function tryParseJson<T>(text: string): T | null {
  try {
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}

function buildTransportErrorBody(
  stage: SafetyreportErrorStage,
  detail: string,
): { stage: SafetyreportErrorStage; detail: string } {
  return { stage, detail };
}
