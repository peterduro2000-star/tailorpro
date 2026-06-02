import { serve } from "https://deno.land/std@0.201.0/http/server.ts";
import { create, getNumericDate, Header, Payload } from "https://deno.land/x/djwt@v2.9/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GOOGLE_KEY = JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_KEY")!);
const PACKAGE_NAME = Deno.env.get("ANDROID_PACKAGE_NAME")!;
const GOOGLE_TOKEN_URI = GOOGLE_KEY.token_uri ?? "https://oauth2.googleapis.com/token";

// ---------------- AUTH CHECK ----------------
async function getUser(token: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: SERVICE_ROLE,
    },
  });

  if (!res.ok) return null;
  return await res.json();
}

// ---------------- GOOGLE TOKEN ----------------
async function getGoogleToken() {
  const jwt = await createGoogleJWT(GOOGLE_KEY);

  const res = await fetch(GOOGLE_TOKEN_URI, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Google token exchange failed: ${res.status} ${t}`);
  }

  const j = await res.json();
  if (!j.access_token) {
    throw new Error("Google token endpoint did not return access_token");
  }

  return j.access_token;
}

async function createGoogleJWT(key: any) {
  const privateKey = await importPrivateKey(key.private_key);

  const header: Header = { alg: "RS256", typ: "JWT" };
  const payload: Payload = {
    iss: key.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: GOOGLE_TOKEN_URI,
    iat: getNumericDate(new Date()),
    exp: getNumericDate(new Date(Date.now() + 60 * 60 * 1000)),
  };

  return await create(header, payload, privateKey);
}

async function importPrivateKey(pem: string) {
  const raw = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");

  const binary = Uint8Array.from(atob(raw), (c) => c.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    binary.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

// ---------------- VERIFY PURCHASE ----------------
async function fetchGooglePurchase(url: string, accessToken: string) {
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Google verification failed: ${res.status} ${t}`);
  }

  return await res.json();
}

async function verifySubscription(accessToken: string, subId: string, purchaseToken: string) {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(PACKAGE_NAME)}` +
    `/purchases/subscriptions/${encodeURIComponent(subId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const data = await fetchGooglePurchase(url, accessToken);

  if (data.purchaseState !== undefined && Number(data.purchaseState) !== 0) {
    throw new Error("Google Play purchase is not completed");
  }

  if (data.cancelReason !== undefined && Number(data.cancelReason) !== 0) {
    throw new Error("Google Play subscription has been cancelled or refunded");
  }

  return data;
}

async function verifyProduct(accessToken: string, productId: string, purchaseToken: string) {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(PACKAGE_NAME)}` +
    `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const data = await fetchGooglePurchase(url, accessToken);

  if (data.purchaseState !== undefined && Number(data.purchaseState) !== 0) {
    throw new Error("Google Play product purchase is not completed");
  }

  return data;
}

async function verifyPurchase(accessToken: string, productId: string, purchaseToken: string) {
  try {
    return await verifySubscription(accessToken, productId, purchaseToken);
  } catch (subscriptionError) {
    try {
      return await verifyProduct(accessToken, productId, purchaseToken);
    } catch (productError) {
      throw new Error(
        `Google verification failed for subscription and product: ${subscriptionError}; ${productError}`,
      );
    }
  }
}

// ---------------- RPC CALL ----------------
async function activate(userId: string, data: any, purchaseToken: string, subId: string) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/activate_license_from_iap`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: `Bearer ${SERVICE_ROLE}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      p_user_id: userId,
      p_tier: "pro",
      p_expires_at: data.expiryTimeMillis ? new Date(Number(data.expiryTimeMillis)).toISOString() : null,
      p_provider: "google_play",
      p_order_id: data.orderId,
      p_purchase_token: purchaseToken,
      p_subscription_id: subId,
    }),
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Supabase RPC failed: ${res.status} ${t}`);
  }

  return await res.json();
}

// ---------------- MAIN ----------------
serve(async (req) => {
  try {
    if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const authHeader = req.headers.get("authorization") ?? "";
    const m = authHeader.match(/Bearer\s+(.+)/);
    if (!m) return new Response("Missing Authorization", { status: 401 });
    const userToken = m[1];

    const user = await getUser(userToken);
    if (!user || !user.id) return new Response("Invalid user", { status: 401 });

    const body = await req.json();
    const purchaseToken = body.purchaseToken;
    const productId = body.productId;
    if (!purchaseToken || !productId) return new Response("Missing fields", { status: 400 });

    const googleToken = await getGoogleToken();
    const purchase = await verifyPurchase(googleToken, productId, purchaseToken);

    const result = await activate(user.id, purchase, purchaseToken, productId);

    return new Response(JSON.stringify({ success: true, result }), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
