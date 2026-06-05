import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmPush } from "../_shared/fcm.ts";
import {
  getFcmTokensForUsers,
  getMesaValor,
  getUsersByPermissionCodes,
  getUsersByRoleNiveles,
  uniqueIds,
} from "../_shared/recipients.ts";
import { createAdminClient } from "../_shared/supabase-admin.ts";
import {
  DatabaseWebhookPayload,
  PedidoRecord,
} from "../_shared/webhook-types.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json() as DatabaseWebhookPayload<PedidoRecord>;
    const pedido = payload.record;

    if (!pedido?.id || !pedido.tenant_id || !pedido.mesa_id) {
      return jsonResponse({ error: "Payload de pedido inválido." }, 400);
    }

    const supabase = createAdminClient();
    const valorMesa = await getMesaValor(supabase, pedido.mesa_id);

    const cocinaUsers = await getUsersByPermissionCodes(
      supabase,
      pedido.tenant_id,
      ["COCINA_VER"],
    );
    const barUsers = await getUsersByRoleNiveles(
      supabase,
      pedido.tenant_id,
      ["bar"],
    );
    const operacionUsers = await getUsersByPermissionCodes(
      supabase,
      pedido.tenant_id,
      ["PEDIDOS_VER"],
    );

    const recipientIds = uniqueIds([
      ...cocinaUsers,
      ...barUsers,
      ...operacionUsers,
    ]);

    const fcmTokens = await getFcmTokensForUsers(
      supabase,
      pedido.tenant_id,
      recipientIds,
    );

    const totalFormatted = Number(pedido.total ?? 0).toFixed(2);
    const sent = await sendFcmPush(fcmTokens, {
      title: `Nuevo pedido — Mesa ${valorMesa}`,
      body: `${pedido.nombre_cliente} — $${totalFormatted}`,
      data: {
        tipo: "nuevo_pedido",
        pedido_id: pedido.id,
        mesa_id: pedido.mesa_id,
        tenant_id: pedido.tenant_id,
      },
    });

    return jsonResponse({
      ok: true,
      pedido_id: pedido.id,
      recipients: recipientIds.length,
      tokens: fcmTokens.length,
      push_sent: sent,
    });
  } catch (error) {
    console.error("notify-nuevo-pedido:", error);
    const message = error instanceof Error
      ? error.message
      : JSON.stringify(error);
    return jsonResponse({ ok: false, error: message }, 500);
  }
});
