import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

// 인터페이스 정의
interface Notification {
  id: string;
  user_id: string;
  body: string;
}

interface WebhookPayload {
  type: string;
  table: string;
  record: any;
  schema: string;
  record_id?: string;
  notification_type?: string;
  title?: string;
  body?: string;
  data?: any;
}

const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}"
);

// Supabase 클라이언트 초기화
const supabase = createClient(
  Deno.env.get("SUPABASE_URL") || "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
);

// 액세스 토큰 가져오기 함수
const getAccessToken = async ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string;
  privateKey: string;
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    jwtClient.authorize((err, tokens) => {
      if (err) {
        console.error("JWT 인증 오류:", err);
        reject(err);
        return;
      }
      console.log("FCM 액세스 토큰 발급 성공");
      resolve(tokens!.access_token!);
    });
  });
};

serve(async (req) => {
  try {
    // 요청에서 데이터 파싱
    const payload: WebhookPayload = await req.json();
    console.log("수신된 웹훅 페이로드:", JSON.stringify(payload));

    const isReportNotification = payload.record_id && payload.notification_type;

    let fcmToken, title, body, notificationData;

    if (isReportNotification) {
      console.log(`리포트 ID ${payload.record_id}에 대한 알림 전송 시작`);

      const { data: report, error: reportError } = await supabase
        .from("reports")
        .select("device_token, device_platform")
        .eq("id", payload.record_id)
        .single();

      if (reportError) {
        console.error(
          `리포트 조회 오류 (ID: ${payload.record_id}):`,
          reportError
        );
        return new Response(
          JSON.stringify({
            error: "리포트를 찾을 수 없습니다",
            details: reportError,
          }),
          {
            status: 404,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      if (!report.device_token) {
        console.warn(`디바이스 토큰 없음 (리포트 ID: ${payload.record_id})`);
        return new Response(
          JSON.stringify({ error: "디바이스 토큰이 없습니다" }),
          {
            status: 400,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      fcmToken = report.device_token;
      title = payload.title || "알림";
      body = payload.body || "";
      notificationData = payload.data || {};

      // 필수 데이터가 문자열인지 확인하고 변환
      Object.keys(notificationData).forEach((key) => {
        if (typeof notificationData[key] !== "string") {
          notificationData[key] = String(notificationData[key]);
        }
      });

      // notification_type 추가
      if (payload.notification_type) {
        notificationData.notification_type = payload.notification_type;
      }

      console.log("알림 정보:", {
        token: fcmToken.substring(0, 10) + "...", // 보안을 위해 토큰 일부만 로깅
        title,
        body,
        data: notificationData,
      });
    } else {
      console.error("잘못된 웹훅 페이로드 형식:", JSON.stringify(payload));
      return new Response(
        JSON.stringify({ error: "올바르지 않은 요청 형식입니다" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    try {
      // 액세스 토큰 가져오기
      console.log("FCM 액세스 토큰 요청 시작");
      const accessToken = await getAccessToken({
        clientEmail: FIREBASE_SERVICE_ACCOUNT.client_email,
        privateKey: FIREBASE_SERVICE_ACCOUNT.private_key?.replace(/\\n/g, "\n"),
      });

      // FCM 메시지 구성
      const message = {
        message: {
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: notificationData,
          android: {
            notification: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              channel_id: "high_importance_channel",
            },
            priority: "high",
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                badge: 1,
                sound: "default",
                content_available: true,
              },
            },
          },
        },
      };

      console.log(
        "FCM 메시지 구성 완료:",
        JSON.stringify({
          ...message,
          message: {
            ...message.message,
            token: "토큰 생략", // 로그에 토큰 전체를 노출하지 않음
          },
        })
      );

      // FCM HTTP v1 API 호출
      const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${FIREBASE_SERVICE_ACCOUNT.project_id}/messages:send`;
      console.log(`FCM API 호출 시작: ${fcmEndpoint}`);

      const fcmResponse = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      });

      const fcmResult = await fcmResponse.json();
      console.log("FCM 응답:", JSON.stringify(fcmResult));

      // 응답 상태 확인
      if (fcmResponse.status < 200 || fcmResponse.status > 299) {
        console.error("FCM 오류 응답:", {
          status: fcmResponse.status,
          body: fcmResult,
        });

        // 토큰 관련 오류 체크
        if (
          fcmResult.error?.status === "INVALID_ARGUMENT" ||
          fcmResult.error?.status === "NOT_FOUND" ||
          (fcmResult.error?.message &&
            fcmResult.error.message.includes("token"))
        ) {
          console.error(
            "FCM 토큰이 유효하지 않거나 만료되었습니다",
            fcmResult.error
          );

          // 선택적: 데이터베이스에서 유효하지 않은 토큰 표시
          try {
            await supabase
              .from("reports")
              .update({ device_token_valid: false })
              .eq("id", payload.record_id);
            console.log(
              `토큰 무효화 플래그 설정 (리포트 ID: ${payload.record_id})`
            );
          } catch (updateError) {
            console.error("토큰 상태 업데이트 실패:", updateError);
          }
        }

        throw new Error(`FCM 전송 실패: ${JSON.stringify(fcmResult)}`);
      }

      console.log("FCM 알림 전송 성공:", fcmResult);
      return new Response(
        JSON.stringify({
          success: true,
          fcmResult,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    } catch (fcmError) {
      console.error("FCM 처리 중 오류:", fcmError);
      throw fcmError; // 외부 catch 블록에서 처리
    }
  } catch (error) {
    console.error("전체 처리 중 오류:", error);
    return new Response(
      JSON.stringify({
        error: error.message,
        stack: error.stack,
        name: error.name,
        cause: error.cause,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
