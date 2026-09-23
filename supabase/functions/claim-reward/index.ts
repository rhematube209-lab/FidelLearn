/**
 * claim-reward Edge Function
 *
 * Called by the Flutter sync engine when a student completes a verifiable event.
 * The client sends an event CLAIM — not an amount.
 * The server determines the reward amount from the server-controlled reward_rules table.
 *
 * Request (authenticated POST):
 *   {
 *     "event_type":      "exam_completed" | "daily_streak" | "challenge_completed" | ...,
 *     "source_entity_id": "<attempt_uuid> | <date_string> | <challenge_uuid>",
 *     "idempotency_key":  "exam_completed_<attempt_uuid>_<user_id>"
 *   }
 *
 * The client MUST NOT send an `amount` field. Any amount in the request is ignored.
 *
 * Response 200: { ledger_entry: { id, user_id, amount, transaction_type, ... } }
 * Response 400: { error: "..." }   — invalid payload
 * Response 401: { error: "..." }   — unauthenticated
 * Response 409: { ledger_entry: existing_entry } — already claimed (idempotent)
 * Response 500: { error: "..." }   — internal error
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle preflight CORS
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

  // Use the service key for internal RPC — never expose to client
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  // Verify the JWT and extract the authenticated user
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

  const { event_type, source_entity_id, idempotency_key } = body as {
    event_type?: string;
    source_entity_id?: string;
    idempotency_key?: string;
  };

  if (!event_type || typeof event_type !== 'string') {
    return jsonError(400, 'Missing or invalid event_type');
  }
  if (!source_entity_id || typeof source_entity_id !== 'string') {
    return jsonError(400, 'Missing or invalid source_entity_id');
  }
  if (!idempotency_key || typeof idempotency_key !== 'string') {
    return jsonError(400, 'Missing or invalid idempotency_key');
  }

  // Validate idempotency_key format to prevent injection (alphanumeric + _ - .)
  if (!/^[\w\-\.]{1,255}$/.test(idempotency_key)) {
    return jsonError(400, 'Invalid idempotency_key format');
  }

  // ── 3. Generate a new UUID for the ledger row ─────────────────────────────
  const newLedgerId = crypto.randomUUID();

  // ── 4. Call internal SECURITY DEFINER function ────────────────────────────
  //    This function:
  //      a) Loads server-controlled reward amount from reward_rules
  //      b) Verifies source entity ownership
  //      c) Checks idempotency
  //      d) Atomically inserts the ledger row with server-determined amount
  const { data: ledgerEntry, error: rpcError } = await supabaseAdmin.rpc(
    'claim_reward_internal',
    {
      p_user_id:         user.id,
      p_event_type:      event_type,
      p_source_id:       source_entity_id,
      p_idempotency_key: idempotency_key,
      p_ledger_id:       newLedgerId,
    },
  );

  if (rpcError) {
    const code = rpcError.code;
    // Translate PostgreSQL error codes to HTTP statuses
    if (code === 'invalid_parameter_value') {
      return jsonError(400, rpcError.message);
    }
    if (code === 'insufficient_privilege') {
      return jsonError(403, rpcError.message);
    }
    console.error('claim_reward_internal error:', rpcError);
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
