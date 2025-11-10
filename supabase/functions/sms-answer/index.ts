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

function parseReportId(message: string): string | null {
  const match = message.match(/SPP-\d{4}-\d{7}/);
  return match ? match[0] : null;
}

function parseProcessed(message: string): boolean | null {
  const match = message.match(/처리결과\s*[:：]?\s*(불?수용)/);
  return match ? match[1] === "수용" : false;
}

// 수신 기기에서 훅으로 자동 호출
serve(async (req) => {
  try {
    if (req.method !== "POST") return methodNotAllowed();

    const { message } = await req.json();
    if (!message) return badRequest("message required");

    logDebug("Received answer message:", message);

    const processed = parseProcessed(message);
    const reportId = parseReportId(message);
    if (!reportId) {
      return jsonErr("report_id not found in message", 400);
    }

    logDebug("Parsed args:", reportId, processed);

    const { data: report, error: fetchErr } = await supabase
      .from("reports")
      .select("id, report_id, answer")
      .eq("report_id", reportId)
      .single();

    if (fetchErr || !report) {
      logDebug("Report not found:", { reportId, fetchErr });
      return jsonErr(`Report with report_id ${reportId} not found`, 404, {
        report_id: reportId,
        error: fetchErr,
      });
    }

    const { data: updated, error: updateErr } = await supabase
      .from("reports")
      .update({ answer: message, processed: processed })
      .eq("report_id", reportId)
      .select();

    if (updateErr) {
      logDebug("Failed to update:", updateErr);
      return jsonErr("Failed to update", 500, {
        supabase_error: updateErr,
      });
    }

    logDebug("Successfully updated:", {
      id: report.id,
      report_id: reportId,
    });

    return jsonOk({
      id: report.id,
      report_id: reportId,
      answer_length: message.length,
    });
  } catch (e) {
    logDebug("Function error", e);
    return jsonErr(e instanceof Error ? e.message : String(e), 500);
  }
});
