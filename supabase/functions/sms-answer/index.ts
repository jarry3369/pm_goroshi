import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  jsonOk,
  jsonErr,
  methodNotAllowed,
  badRequest,
  logDebug,
} from "../_shared/utils.ts";

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

    // 토큰 발행
    logDebug("Requesting access token...");
    const tokenUrl = "https://www.safetyreport.go.kr/oauth/token";
    const tokenParams = new URLSearchParams({
      client_id: "web",
      grant_type: "password",
      loginType: "2",
      username: reportId,
      password: Deno.env.get("AUTHENTICATION_PHONE_NUMBER") || "",
    });

    const tokenResponse = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
        Referer: "https://www.safetyreport.go.kr/",
      },
      body: tokenParams.toString(),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      logDebug("Failed to get access token:", {
        status: tokenResponse.status,
        errorText,
      });
      return jsonErr(`Failed to get access token: ${errorText}`, 500);
    }

    const { access_token: accessToken } = await tokenResponse.json();
    logDebug("Successfully obtained access token.");

    const memberApiUrl = `https://www.safetyreport.go.kr/api/v1/common/auth/member/${reportId}?loginid=${reportId}&authnum=0`;
    const memberResponse = await fetch(memberApiUrl, {
      headers: {
        Authorization: `BEARER ${accessToken}`,
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
        Referer: "https://www.safetyreport.go.kr/",
      },
    });

    if (!memberResponse.ok) {
      const errorText = await memberResponse.text();
      logDebug("Failed to get ACNT_ID:", {
        status: memberResponse.status,
        errorText,
      });
      return jsonErr(`Failed to get ACNT_ID: ${errorText}`, 500);
    }

    const memberData = await memberResponse.json();
    const acntId = memberData?.result?.ACNT_ID; // ACNT_ID 추출

    if (!acntId) {
      logDebug("ACNT_ID not found in member response:", memberData);
      return jsonErr("ACNT_ID not found in member response", 500);
    }
    logDebug("Successfully obtained ACNT_ID:", acntId);

    const detailApiUrl = `https://www.safetyreport.go.kr/api/v1/portal/mypage/mysafereport/${acntId}`;
    const detailResponse = await fetch(detailApiUrl, {
      headers: {
        Authorization: `BEARER ${accessToken}`,
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
        Referer: "https://www.safetyreport.go.kr/",
      },
    });

    if (!detailResponse.ok) {
      logDebug("Failed to fetch report details:", {
        status: detailResponse.status,
      });
    }

    const detailData = await detailResponse.json();
    const firstAnswer = detailData.result?.answers?.[0];

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
        processed: firstAnswer.C_MANAGER_TYPE_NM == "수용",
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
    logDebug("Critical function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
