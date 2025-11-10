import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  jsonOk,
  jsonErr,
  methodNotAllowed,
  logDebug,
  badRequest,
} from "../_shared/utils.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// 수신 기기에서 훅으로 자동 호출
serve(async (req) => {
  try {
    if (req.method !== "POST") methodNotAllowed();

    const { code } = await req.json();
    if (!code) return badRequest("code required");

    // 세션 큐에서 가장 오래된 미매칭 세션 조회
    const { data: session } = await supabase
      .from("report_sessions")
      .select("id, report_id")
      .eq("matched", false)
      .order("created_at", { ascending: true })
      .limit(1)
      .single();

    if (!session) {
      return jsonOk({ consumed: false });
    }

    // 경합방지
    const { data: claimed, error: claimErr } = await supabase
      .from("report_sessions")
      .update({ matched: true })
      .eq("id", session.id)
      .eq("matched", false)
      .select()
      .single();

    if (claimErr || !claimed) {
      // TODO: 경합으로 선점 실패 재시도 처리
      return jsonOk({ consumed: false, reason: "race" });
    }

    const { error: uerr } = await supabase
      .from("reports")
      .update({ sms_code: code, status: "ready" })
      .eq("id", session.report_id);
    if (uerr) {
      return jsonErr("failed to update report", 500, { supabase_error: uerr });
    }

    // submit 동기 실행
    const fnUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/report-submit`;
    await fetch(fnUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ report_id: session.report_id }),
    });

    return jsonOk({ report_id: session.report_id });
  } catch (e) {
    logDebug("Function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
