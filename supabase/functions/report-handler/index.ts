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

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// reports 테이블 row after inster trigger로 즉시 호출
serve(async (req) => {
  try {
    if (req.method !== "POST") return methodNotAllowed();

    // realtime 기반 payload
    const payload = await req.json();
    const report = payload.record;
    const report_id = report?.id;

    if (!report_id) return badRequest("report_id missing");

    logDebug("target:", report_id);

    const PHONE = normalizePhone(
      Deno.env.get("AUTHENTICATION_PHONE_NUMBER") || ""
    );
    if (!PHONE.plain)
      return jsonErr("env AUTHENTICATION_PHONE_NUMBER not set", 500);

    const crftcReqBody = new URLSearchParams();
    crftcReqBody.set("MOBLPHON_NO", PHONE.plain);
    crftcReqBody.set("SMS_CRTFC_SE", "01");
    crftcReqBody.set("SMS_CRTFC_TY", "01");
    crftcReqBody.set("CRTFC_TYPE", "M");

    // SMS 인증 코드 요청
    const res = await fetch(
      `${SAFETYREPORT_BASE_URL}/api/v1/portal/common/sms`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "User-Agent": UA,
          Accept: "*/*",
        },
        body: crftcReqBody.toString(),
      }
    );

    const j = await res.json().catch(() => ({}));
    logDebug("j sms response", j);

    const smsReqId = j?.SMS_CRTFC_ID;

    if (!res.ok || !smsReqId) {
      return jsonErr("portal sms request failed", 502, {
        step: "sms",
        status: res.status,
        body: j,
      });
    }

    // SMS 인증 매칭용 데이터 저장 및 status 업데이트
    const { data: updateData, error: uerr } = await supabase
      .from("reports")
      .update({ sms_req_id: smsReqId, status: "waiting_code" })
      .eq("id", report_id)
      .select("*");
    logDebug("update target report to waiting_code", { updateData, uerr });

    if (uerr)
      return jsonErr("failed to update report", 500, { supabase_error: uerr });

    // 중복방지 upsert
    await supabase.from("report_sessions").upsert({ report_id });
    return jsonOk({ report_id, sms_req_id: smsReqId });
  } catch (e) {
    logDebug("Function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
