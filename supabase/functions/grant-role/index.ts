/**
 * grant-role Edge Function
 *
 * Allows a verified platform_admin to grant a role to another user.
 * The caller's role is verified against the database — never trusted from the JWT claims
 * or request body.
 *
 * Request (authenticated POST):
 *   {
 *     "target_user_id": "<uuid>",
 *     "role_id":        "student" | "teacher" | "school_admin" | "platform_admin"
 *   }
 *
 * Response 200: { success: true }
 * Response 400: { error: "..." }   — invalid payload or unknown role
 * Response 401: { error: "..." }   — unauthenticated
 * Response 403: { error: "..." }   — caller is not a platform_admin
 * Response 500: { error: "..." }   — internal error
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const VALID_ROLES = new Set(['student', 'teacher', 'school_admin', 'platform_admin']);

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

  const { target_user_id, role_id } = body as {
    target_user_id?: string;
    role_id?: string;
  };

  if (!target_user_id || typeof target_user_id !== 'string') {
    return jsonError(400, 'Missing or invalid target_user_id');
  }
  if (!role_id || typeof role_id !== 'string' || !VALID_ROLES.has(role_id)) {
    return jsonError(400, `Invalid role_id. Must be one of: ${[...VALID_ROLES].join(', ')}`);
  }

  // ── 3. Call internal SECURITY DEFINER function ────────────────────────────
  //    The function itself re-verifies the actor has platform_admin.
  //    Double-checking here AND inside the DB function is defence-in-depth.
  const { error: rpcError } = await supabaseAdmin.rpc(
    'grant_role_internal',
    {
      p_actor_id:  user.id,
      p_target_id: target_user_id,
      p_role_id:   role_id,
    },
  );

  if (rpcError) {
    const code = rpcError.code;
    if (code === 'insufficient_privilege') {
      return jsonError(403, 'Caller does not have platform_admin role');
    }
    if (code === 'invalid_parameter_value') {
      return jsonError(400, rpcError.message);
    }
    console.error('grant_role_internal error:', rpcError);
    return jsonError(500, 'Internal server error');
  }

  return new Response(
    JSON.stringify({ success: true }),
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
