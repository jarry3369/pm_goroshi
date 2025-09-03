import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  badRequest,
  jsonOk,
  jsonErr,
  methodNotAllowed,
  normalizePhone,
  logDebug,
} from "../_shared/utils.ts";
import { SAFETYREPORT_BASE_URL, UA } from "../_shared/constants.ts";

/**
 * (참조) report 테이블 스키마
 */
type Report = {
  id: string;
  status: string;
  sms_req_id: string | null;
  sms_code: string | null;
  content: Payload;
};

/**
 * (참조) report 테이블 / content 필드 스키마
 */
type Payload = Partial<{
  qr_data: string;
  latitude: number;
  longitude: number;
  location: string;
  image_urls: string[];
  description: string;
  company_name: string | null;
  serial_number: string | null;
  violation_type: { id: string; name: string };
  submission_time: string;
  phone: string;
  name: string;
  email: string;
}>;

const KAKAO_REST_API_KEY = Deno.env.get("KAKAO_REST_API_KEY");
if (!KAKAO_REST_API_KEY) jsonErr("KAKAO_REST_API_KEY not set", 500);

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// 안전신문고 사이트에 하드코딩된 메시지 상수
const FILE_TIME_MESSAGE_4 =
  "* 안전신문고 신고파일(사진·동영상) 촬영시간 및 경로 안내 *\n" +
  "* G:휴대폰(안전신문고 앱 제외) 또는 PC에 저장된 사진·동영상\n" +
  "* C:안전신문고 앱으로 현장에서 촬영 후 바로 신고한 사진·동영상\n" +
  "* S:안전신문고 앱으로 촬영 및 저장 후 신고한 사진·동영상\n" +
  "* 안전신문고 앱으로 촬영한 사진은 촬영 일시가 자동으로 표기되고, 위·변조 방지기능을 탑재\n\n" +
  "(( 신고인 개인정보 보호 안내 - 개인정보보호법 제 17조, 민원처리에 관한 법률 제7조 ))\n" +
  "* 신고인 정보 등 개인정보와 신고내용은 신고처리 및 관리 목적으로만 사용하여야 하며, 정보주체의 동의 없이 무단으로 제3자에게 제공할 수 없으니 처리기관에서는 개인정보 관리에 철저를 기해 주시기 바랍니다.\n\n" +
  "(( 신고 접수경로 안내 ))\n";

const FILE_TIME_MESSAGE_5 =
  "* G:휴대폰(안전신문고 앱 제외) 또는 PC에 저장된 사진·동영상\n" +
  "* C:안전신문고 앱으로 현장에서 촬영 후 바로 신고한 사진·동영상\n" +
  "* S:안전신문고 앱으로 촬영 및 저장 후 신고한 사진·동영상\n" +
  "* 안전신문고 앱으로 촬영한 사진은 촬영 일시가 자동으로 표기되고, 위·변조 방지기능을 탑재\n\n";

// 특수문자 검열용
function removeNonPrintableChars(str: string): string {
  // deno-lint-ignore no-control-regex
  return str.replace(/[\x00-\x1F\x7F-\x9F]/g, "");
}

// 쿠키 맵을 http 헤더로 변환
function cookieHeader(jar: Record<string, string>) {
  return Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join("; ");
}
// 응답 헤더의 set-cookie를  쿠키 맵에 merge
function mergeSetCookies(jar: Record<string, string>, res: Response) {
  const all = res.headers.get("set-cookie");
  if (!all) return;
  for (const part of all.split(/,(?=[^ ;]+=)/)) {
    const first = part.split(";")[0].trim();
    const eq = first.indexOf("=");
    if (eq > 0) jar[first.slice(0, eq)] = first.slice(eq + 1);
  }
}

async function postForm(
  url: string,
  params: URLSearchParams | FormData,
  jar: Record<string, string>,
  referer: string = `${SAFETYREPORT_BASE_URL}/`
): Promise<Response> {
  const headers: Record<string, string> = {
    "User-Agent": UA,
    "X-Requested-With": "XMLHttpRequest",
    Accept: "*/*",
    Cookie: cookieHeader(jar),
    Origin: SAFETYREPORT_BASE_URL,
    Referer: referer,
  };
  if (params instanceof URLSearchParams) {
    headers["Content-Type"] =
      "application/x-www-form-urlencoded; charset=UTF-8";
  }

  const res = await fetch(url, {
    method: "POST",
    headers: headers,
    body: params,
  });
  mergeSetCookies(jar, res);
  return res;
}

async function buildRAddressInfo({
  location,
  latitude,
  longitude,
}: Payload): Promise<{ roadAddress: string; zipCode: string }> {
  if (!KAKAO_REST_API_KEY) {
    return { roadAddress: "", zipCode: "" };
  }
  const url = `https://dapi.kakao.com/v2/local/geo/coord2address.json?x=${longitude}&y=${latitude}`;
  const headers = { Authorization: `KakaoAK ${KAKAO_REST_API_KEY}` };

  try {
    const res = await fetch(url, { headers });
    const j = await res.json();

    // 가끔씩 도로명 조회 안되는 경우 사용자 입력 주소 및 임의 zipcode로 대체
    const roadAddress = j.documents[0]?.road_address?.address_name || location;
    const zipCode = j.documents[0]?.road_address?.zone_no || "01111";

    return { roadAddress, zipCode };
  } catch (e) {
    console.error("failed to fetching address info", e);
    return { roadAddress: "", zipCode: "" };
  }
}

// daum map imageservice 생성
async function buildStaticMapUrl(
  lat: number,
  lng: number,
  width: number = 704,
  height: number = 321
): Promise<string> {
  if (!KAKAO_REST_API_KEY) {
    return "";
  }

  // daum map 지원 좌표계 WCONGNAMUL 형식으로 변환
  const transCoordUrl = `https://dapi.kakao.com/v2/local/geo/transcoord.json?x=${lng}&y=${lat}&input_coord=WGS84&output_coord=WCONGNAMUL`;
  const headers = { Authorization: `KakaoAK ${KAKAO_REST_API_KEY}` };

  try {
    const res = await fetch(transCoordUrl, { headers });
    const j = await res.json();

    if (res.ok && j.documents && j.documents.length > 0) {
      const tmX = j.documents[0].x;
      const tmY = j.documents[0].y;

      const params = new URLSearchParams({
        IW: width.toString(),
        IH: height.toString(),
        MX: tmX.toString(),
        MY: tmY.toString(),
        CX: tmX.toString(),
        CY: tmY.toString(),
        SCALE: "2.5",
        service: "open",
      });

      return `http://map2.daum.net/map/imageservice?${params.toString()}`;
    } else {
      console.error("failed to transCoord:", j);
      return "";
    }
  } catch (e) {
    console.error("failed to build map url:", e);
    return "";
  }
}

// 리포트 본문 생성
function buildContentsMessage(p: Payload, filesMetaDates: string[]): string {
  const description = removeNonPrintableChars(
    p.description || "신고 내용"
  ).trim();
  const companyName = removeNonPrintableChars(p.company_name || "").trim();
  const location = removeNonPrintableChars(p.location || "").trim();

  const details = [description];
  if (p.qr_data) details.push(`* QR정보: ${p.qr_data}`);
  if (companyName) details.push(`* 업체명: ${companyName}`);
  if (p.serial_number) details.push(`* 기기 시리얼 번호: ${p.serial_number}`);

  let message = `${p?.image_urls
    ?.map((u) => u)
    ?.join(`\n`)}\n\n${JSON.stringify(p, null, 2)}`;

  if (details.length > 0) {
    message += `\n${details.join("\n")}\n`;
  }
  message += "\n 업체에 재발 방지 요청 부탁드립니다. 감사합니다.";

  message += "\n\n\n\n";
  message += FILE_TIME_MESSAGE_4;
  message += "\n";

  for (let i = 0; i < filesMetaDates.length; i++) {
    message += `* (${i + 1}/${filesMetaDates.length}) G: ${
      filesMetaDates[i]
    }\n`;
  }

  message += `* 위도:${p.latitude ?? 0} 경도:${p.longitude ?? 0}\n`;
  if (location) {
    message += `* 주소: ${location}\n`;
  }

  message += FILE_TIME_MESSAGE_5;
  message += `본 신고는 안전신문고 포털의 생활불편 신고-자전거·이륜차 방치 및 불편 메뉴로 접수된 신고입니다.`;

  return message;
}

// safereport form 객체 생성
function buildForm(
  payload: Payload,
  smsId: string,
  authCode: string,
  serverFileNames: string[],
  realFileNames: string[],
  addressInfo: { roadAddress: string; zipCode: string },
  staticMapUrl: string
): URLSearchParams {
  const p = payload as Required<Payload>;

  const title = removeNonPrintableChars(
    (p.description || "생활불편 신고").trim()
  );

  const filesMetaDates = realFileNames.map(() => {
    const d = new Date();
    return `${d.getFullYear()}/${(d.getMonth() + 1)
      .toString()
      .padStart(2, "0")}/${d.getDate().toString().padStart(2, "0")} ${d
      .getHours()
      .toString()
      .padStart(2, "0")}:${d.getMinutes().toString().padStart(2, "0")}:${d
      .getSeconds()
      .toString()
      .padStart(2, "0")}`;
  });
  const contents = buildContentsMessage(p, filesMetaDates);

  const params = new URLSearchParams();
  params.set("ReportTypeSelect", "02"); // 안전신문고/생활불편 신고
  params.set("C_SSNPC_CD", "DR");
  params.set("C_SSNPC_TYPE", "02"); // 안전신고/생활불편 신고/자전거·이륜차 방치 및 불편
  params.set("SMS_CRTFC_ID", smsId); // sms 인증 세션 id
  params.set("SMS_CRTFC_AT", "Y");
  params.set("C_A_W", String(p.latitude ?? 0));
  params.set("C_A_E", String(p.longitude ?? 0));
  params.set("C_ZIP", addressInfo.zipCode);
  params.set("C_ZIP_TYPE", "R"); // R(도로명)/J(구주소) 도로명 기준 R로 고정.
  params.set("RN_ADRES", addressInfo.roadAddress);
  params.set("C_A_ADD1", "");
  params.set("C_A_ADD2", p.location ?? ""); // location 값을 C_A_ADD2에 유지
  params.set("C_ADD1", "");
  params.set("C_ADD2", "");
  params.set("C_A_TITLE", title); // 리포트 제목
  params.set("C_A_CONTENTS", contents); // 리포트 본문
  params.set("AUTH_NUMBER", authCode); // sms 인증 코드
  params.set("C_OPEN", "0");
  params.set("D_OPEN", "1");
  params.set("E_OPEN", "T10000");
  params.set("instSearchWord", "");
  params.set("C_GROUP_NAME", "");
  params.set("C_A_ORG_NAME", "");
  params.set("C_A_ORG", "");
  params.set("C_CORONA", "");
  params.set("C_CORONA_VAL", "");
  params.set("C_FILES", serverFileNames.join("|"));
  params.set("C_FILES_VIEW", "1|" + serverFileNames.map(() => "1").join("|"));
  params.set("C_R_FILES", realFileNames.join("|"));
  params.set("C_R_FILES_TIME", filesMetaDates.join("|"));
  params.set("C_ID", normalizePhone(p.phone ?? "").plain);
  params.set("INSTT_CODE", "");
  params.set("SEHIGH_INSTT_CODE", "");
  params.set("BEST_INSTT_CODE", "");
  params.set("GRP_ENTRPRS_CODE", "");
  params.set("C_RELATION2", "1");
  params.set("C_RELATION3", "");
  params.set("STTEMNT_IMAGE_URL", staticMapUrl);
  params.set("NFVNZ_CD", "");
  params.set("SIDO_INSTT_CODE", "");
  params.set("SIGUNGU_INSTT_CODE", "");
  params.set("PROCESS_NTCN_YN", "Y");
  params.set("C_TYPE", "0");
  params.set("C_NAME", p.name ?? ""); // 인적사항 필드 이름
  params.set("C_EMAIL", p.email ?? ""); // 인적사항 필드 이름
  params.set("emailSelect", "선택하세요"); // 기본값으로 고정
  params.set("agreeUseMyInfo", "Y"); // 인적사항 필드 개인정보 수집 동의
  params.set("C_PHONE2", normalizePhone(p.phone ?? "").dashed); // 인적사항 필드 연락처
  params.set("C_TMPFLAG", "");

  return params;
}

// sms-serve 에서 트리거
serve(async (req) => {
  try {
    if (req.method !== "POST") return methodNotAllowed();

    const { report_id } = await req.json();
    if (!report_id) return badRequest("report_id missing");

    const { data: report, error } = await supabase
      .from("reports")
      .select("id, status, sms_req_id, sms_code, content")
      .eq("id", report_id)
      .single();

    if (error || !report) {
      const msg = `report ${report_id} not found`;
      logDebug(msg);
      return jsonErr(msg, 404);
    }
    if (!report.sms_req_id || !report.sms_code) {
      const msg = "sms_req_id or sms_code missing";
      await supabase
        .from("reports")
        .update({ status: "failed", error_message: msg })
        .eq("id", report.id);

      logDebug(msg);
      return jsonErr(msg, 400);
    }

    const adminInfo = JSON.parse(Deno.env.get("ADMIN_INFO")!);
    const enrichedContent = {
      ...report.content,
      name: adminInfo.name,
      email: adminInfo.email,
      phone: adminInfo.phone,
    };

    // 주소 정보 및 static 지도 이미지 생성
    let addressInfo = { roadAddress: "", zipCode: "" };
    if (enrichedContent.latitude && enrichedContent.longitude) {
      addressInfo = await buildRAddressInfo(enrichedContent);
    }
    let staticMapUrl = "";
    if (enrichedContent.latitude && enrichedContent.longitude) {
      staticMapUrl = await buildStaticMapUrl(
        enrichedContent.latitude,
        enrichedContent.longitude
      );
    }

    // SMS 인증 -> 리포트 제출 흐름까지 세션 유지를 위한 쿠키 생성
    const jar: Record<string, string> = {};
    const warmup = await fetch(`${SAFETYREPORT_BASE_URL}/`, {
      headers: { "User-Agent": UA },
    });
    mergeSetCookies(jar, warmup);
    logDebug("cookie f:", jar);

    const PHONE = normalizePhone(
      Deno.env.get("AUTHENTICATION_PHONE_NUMBER") || ""
    );
    if (!PHONE.plain)
      return jsonErr("env AUTHENTICATION_PHONE_NUMBER not set", 500);

    const crftcReqBody = new URLSearchParams();
    crftcReqBody.set("SMS_CRTFC_ID", report.sms_req_id);
    crftcReqBody.set("SMS_CRTFC_NO", report.sms_code);
    crftcReqBody.set("SMS_CRTFC_TY", "01");
    crftcReqBody.set("MOBLPHON_NO", PHONE.plain);

    const r1 = await postForm(
      `${SAFETYREPORT_BASE_URL}/api/v1/portal/common/sms/smsCrtfcTy`,
      crftcReqBody,
      jar
    );
    const j1 = await r1.json().catch(() => ({}));

    if (!r1.ok || (j1?.result && j1.result !== "success")) {
      const msg = `sms code authentication failed: ${JSON.stringify(
        j1 || r1.statusText
      )}`;
      await supabase
        .from("reports")
        .update({ status: "failed", error_message: msg })
        .eq("id", report.id);

      logDebug(msg);
      return jsonErr(msg, 400, { step: "verify", status: r1.status, body: j1 });
    }
    logDebug("sms code verified");

    // raonk 업로더 후킹 실패
    // 파일 업로드 비활성
    const serverFileNames: string[] = [];
    const realFileNames: string[] = [];

    const params = buildForm(
      enrichedContent as Payload,
      report.sms_req_id,
      report.sms_code,
      serverFileNames,
      realFileNames,
      addressInfo,
      staticMapUrl
    );
    logDebug("safereport req params:", params.toString());

    const r2 = await postForm(
      `${SAFETYREPORT_BASE_URL}/api/v1/portal/safereport/safereport`,
      params,
      jar
    );
    logDebug("final status:", r2.status);

    const t2 = await r2.text();
    let j2: any = null;
    try {
      j2 = JSON.parse(t2);
    } catch {
      // ignore
    }

    if (r2.ok && (!j2 || j2?.result === "success")) {
      const submissionDetails = j2 || t2;
      await supabase
        .from("reports")
        .update({
          status: "submitted",
          processed: true,
          report_id: j2?.STTEMNT_NO,
        })
        .eq("id", report.id);

      return jsonOk({ result: submissionDetails });
    } else {
      const msg = `failed to report: ${JSON.stringify(j2 || t2)}`;
      await supabase
        .from("reports")
        .update({ status: "failed", error_message: msg })
        .eq("id", report.id);

      logDebug(msg);
      return jsonErr(msg, 502, {
        step: "submit",
        status: r2.status,
        body: j2 || t2,
      });
    }
  } catch (e) {
    logDebug("Function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
