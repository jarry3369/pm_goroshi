import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    }
  );
  const payload = await req.json();
  const record = payload.record;

  const timestamp = Math.floor(new Date(record.timestamp).getTime() / 1000);

  const string = `<@745820946664783903>\nNew Request\nid: ${
    record.id
  }\n[map](https://google.co.kr/maps/place/${record?.content?.latitude},${
    record?.content?.longitude
  })\nimages: ${record?.content?.image_urls
    .map((u, i) => `[link${i}](<${u}>)`)
    .join(", ")}\n\`\`\`json${JSON.stringify(record?.content, null, 2)}\`\`\` `;

  const message = {
    content: string,
    // embeds: [
    //   {
    //     title: "New Request",
    //     color: 0x00aaff,
    //     fields: string
    //       .split("\n")
    //       .slice(2)
    //       .map((line) => {
    //         const [name, ...rest] = line.split("￥");
    //         return {
    //           name: name.trim(),
    //           value: rest.join("￥").trim() || "-",
    //           inline: true,
    //         };
    //       }),
    //     footer: { text: "bonkris" },
    //     timestamp: new Date().toISOString(),
    //   },
    // ],
  };

  const response = await fetch(Deno.env.get("DISCORD_WEBHOOK_URL") ?? "", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  });

  if (!response.ok) {
    console.error("Discord webhook call failed:", await response.text());
    return new Response(
      JSON.stringify({ error: "Discord notification failed" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
