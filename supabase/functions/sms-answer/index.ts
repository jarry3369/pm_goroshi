import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  jsonOk,
  jsonErr,
  methodNotAllowed,
  badRequest,
  logDebug,
} from "../_shared/utils.ts";
import {
  fetchMemberAccount,
  fetchSafeReportDetails,
  issuePortalToken,
  newSafetyreportCookieJar,
  SafetyreportApiError,
} from "../_shared/safetyreport_api.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// 수신 기기에서 훅으로 자동 호출
serve(async (req) => {
  try {
    if (req.method !== "POST") return methodNotAllowed();

    const { reportId } = await req.json();
    if (!reportId) return badRequest("report_id required");

    const jar = newSafetyreportCookieJar();
    const tokenResult = await issuePortalToken(
      reportId,
      Deno.env.get("AUTHENTICATION_PHONE_NUMBER") || "",
      jar,
    );
    const accessToken = tokenResult.data.access_token!;

    const memberResult = await fetchMemberAccount({
      reportId,
      accessToken,
      jar,
    });
    const acntId = memberResult.data.result?.ACNT_ID!;

    const detailResult = await fetchSafeReportDetails({
      accountId: acntId,
      accessToken,
      jar,
    });
    const firstAnswer = detailResult.data.result?.answers?.[0];

    let finalAnswer = "";
    if (firstAnswer && firstAnswer.C_MANAGE_CONTENTS?.trim()) {
      logDebug("Formatting detailed answer.");
      
      finalAnswer = `처리 결과: ${firstAnswer.C_MANAGER_TYPE_NM || "정보 없음"}

처리 기관 정보
- 기관: ${firstAnswer.C_MANAGE_ORG_NAME || "정보 없음"}
- 담당자: ${firstAnswer.C_MANAGE_MAN || "정보 없음"}
- 연락처: ${firstAnswer.C_MANAGE_MAN_PHONE || "정보 없음"}
- 이메일: ${firstAnswer.C_MANAGE_MAN_EMAIL || "정보 없음"}

---

답변 내용

${firstAnswer.C_MANAGE_CONTENTS}
`.trim();
    } else {
      logDebug("No detailed answer content found, using original message.");
    }

    const { error: updateErr } = await supabase
      .from("reports")
      .update({
        answer: finalAnswer,
        processed: true,
      })
      .eq("report_id", reportId);

    if (updateErr) {
      logDebug("Failed to update db:", updateErr);
      return jsonErr("Failed to update db", 500, {
        supabase_error: updateErr,
      });
    }

    return jsonOk({
      report_id: reportId,
      answer_length: finalAnswer.length,
    });
  } catch (e) {
    if (e instanceof SafetyreportApiError) {
      logDebug("sms-answer safetyreport request failed", {
        step: e.step,
        status: e.status,
      });
      return jsonErr(e.message, 502, {
        step: e.step,
        status: e.status,
        body: e.body,
      });
    }

    logDebug("Critical function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
