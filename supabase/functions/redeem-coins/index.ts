/**
 * redeem-coins Edge Function
 *
 * Called by the Flutter sync engine when a student redeems coins for an item.
 * The client sends a redemption item ID — not a cost.
 * The server determines the cost from the server-controlled redemption_catalog.
 * Balance check and DEBIT insert are performed atomically with concurrency protection.
 *
 * Request (authenticated POST):
 *   {
 *     "redemption_item_id": "exam_unlock_biology_2014",
 *     "idempotency_key":    "redeem_<item_id>_<user_id>_<timestamp>"
 *   }
 *
 * The client MUST NOT send a `cost` or `amount` field. Any such field is ignored.
 *
 * Response 200: { ledger_entry: { id, user_id, amount, transaction_type, ... } }
 * Response 400: { error: "..." }   — invalid payload or unknown item
 * Response 401: { error: "..." }   — unauthenticated
 * Response 402: { error: "..." }   — insufficient balance
 * Response 409: { ledger_entry: existing_entry } — already redeemed (idempotent)
 * Response 500: { error: "..." }   — internal error
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonError(405, 'Method Not Allowed');
  }

  // ── 1. Authenticate caller ────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonError(401, 'Missing Authorization header');
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
    authHeader.replace('Bearer ', ''),
  );

  if (authError || !user) {
    return jsonError(401, 'Invalid or expired token');
  }

  // ── 2. Parse and validate payload ────────────────────────────────────────
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonError(400, 'Request body must be valid JSON');
  }

  const { redemption_item_id, idempotency_key } = body as {
    redemption_item_id?: string;
    idempotency_key?: string;
  };

  if (!redemption_item_id || typeof redemption_item_id !== 'string') {
    return jsonError(400, 'Missing or invalid redemption_item_id');
  }
  if (!idempotency_key || typeof idempotency_key !== 'string') {
    return jsonError(400, 'Missing or invalid idempotency_key');
  }
  if (!/^[\w\-\.]{1,255}$/.test(idempotency_key)) {
    return jsonError(400, 'Invalid idempotency_key format');
  }

  // ── 3. Generate a new UUID for the ledger row ─────────────────────────────
  const newLedgerId = crypto.randomUUID();

  // ── 4. Call internal SECURITY DEFINER function ────────────────────────────
  //    This function:
  //      a) Loads cost from server-controlled redemption_catalog
  //      b) Checks idempotency
  //      c) Acquires advisory lock on user_id to prevent concurrent negative balance
  //      d) Validates current balance >= cost
  //      e) Atomically inserts DEBIT ledger row
  const { data: ledgerEntry, error: rpcError } = await supabaseAdmin.rpc(
    'redeem_coins_atomic',
    {
      p_user_id:         user.id,
      p_item_id:         redemption_item_id,
      p_idempotency_key: idempotency_key,
      p_ledger_id:       newLedgerId,
    },
  );

  if (rpcError) {
    const code = rpcError.code;
    if (code === 'invalid_parameter_value') {
      return jsonError(400, rpcError.message);
    }
    if (code === 'check_violation') {
      // Insufficient balance
      return jsonError(402, 'Insufficient coin balance for this redemption');
    }
    console.error('redeem_coins_atomic error:', rpcError);
    return jsonError(500, 'Internal server error');
  }

  return new Response(
    JSON.stringify({ ledger_entry: ledgerEntry }),
    {
      status: 200,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    },
  );
});

function jsonError(status: number, message: string): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    },
  );
}
