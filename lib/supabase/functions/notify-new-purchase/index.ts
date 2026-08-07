import { serve } from "https://deno.land/std@0.201.0/http/server.ts";

const NOTIFY_EMAIL = "peterduro2000@gmail.com";
const SMTP_HOST = "smtp.gmail.com";
const SMTP_PORT = 465;
const GMAIL_USER = Deno.env.get("GMAIL_USER")!;
const GMAIL_APP_PASSWORD = Deno.env.get("GMAIL_APP_PASSWORD")!;

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    // Only notify on pro upgrades
    if (record.tier !== "pro") {
      return new Response("Not a pro upgrade", { status: 200 });
    }

    const subject = "🎉 New TailorPro Pro Subscriber!";
    const body = `
New Pro subscription activated!

User ID: ${record.user_id}
Order ID: ${record.order_id ?? "N/A"}
Subscription ID: ${record.subscription_id ?? "N/A"}
Expires: ${record.expires_at ?? "N/A"}
Date: ${new Date().toISOString()}

Check Play Console for full details.
    `.trim();

    await sendEmail(subject, body);

    return new Response("Notified", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response(String(e), { status: 500 });
  }
});

async function sendEmail(subject: string, body: string) {
  const { SMTPClient } = await import("https://deno.land/x/denomailer@1.6.0/mod.ts");

  const client = new SMTPClient({
    connection: {
      hostname: SMTP_HOST,
      port: SMTP_PORT,
      tls: true,
      auth: {
        username: GMAIL_USER,
        password: GMAIL_APP_PASSWORD,
      },
    },
  });

  await client.send({
    from: GMAIL_USER,
    to: NOTIFY_EMAIL,
    subject,
    content: body,
  });

  await client.close();
}