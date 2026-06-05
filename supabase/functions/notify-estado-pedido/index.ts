import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFcmPush } from "../_shared/fcm.ts";
import {
  getFcmTokensForUsers,
  getMesaDetails,
  getUsersAtOrAboveNivel,
  getUsersByRoleNiveles,
  uniqueIds,
} from "../_shared/recipients.ts";
import { createAdminClient } from "../_shared/supabase-admin.ts";
import {
  DatabaseWebhookPayload,
  PedidoRecord,
} from "../_shared/webhook-types.ts";

function buildNotification(
  estadoAnterior: string,
  estadoNuevo: string,
  valorMesa: string,
  nombreCliente: string,
): { title: string; body: string; tipo: string } | null {
  if (estadoAnterior === "pendiente" && estadoNuevo === "en_preparacion") {
    return {
      title: `Pedido en preparación — Mesa ${valorMesa}`,
      body: `La cocina tomó el pedido de ${nombreCliente}.`,
      tipo: "pedido_en_preparacion",
    };
  }

  if (estadoAnterior === "en_preparacion" && estadoNuevo === "listo") {
    return {
      title: `¡Pedido listo! — Mesa ${valorMesa}`,
      body: `${nombreCliente} — retirar de cocina/bar.`,
      tipo: "pedido_listo",
    };
  }

  if (estadoAnterior === "listo" && estadoNuevo === "entregado") {
    return {
      title: `Pedido entregado — Mesa ${valorMesa}`,
      body: `${nombreCliente} recibió su pedido.`,
      tipo: "pedido_entregado",
    };
  }

  if (estadoAnterior === "entregado" && estadoNuevo === "completado") {
    return {
      title: `Cuenta cerrada — Mesa ${valorMesa}`,
      body: `Pedido de ${nombreCliente} completado.`,
      tipo: "pedido_completado",
    };
  }

  return null;
}

async function resolveRecipients(
  supabase: ReturnType<typeof createAdminClient>,
  tenantId: string,
  mesaId: string,
  estadoAnterior: string,
  estadoNuevo: string,
): Promise<string[]> {
  const mesa = await getMesaDetails(supabase, mesaId);
  const mozoId = mesa.personal_asignado_id;
  const supervisors = await getUsersAtOrAboveNivel(
    supabase,
    tenantId,
    "supervisor",
  );
  const admins = await getUsersByRoleNiveles(supabase, tenantId, ["admin"]);

  if (estadoAnterior === "pendiente" && estadoNuevo === "en_preparacion") {
    return uniqueIds([...(mozoId ? [mozoId] : []), ...supervisors]);
  }

  if (estadoAnterior === "en_preparacion" && estadoNuevo === "listo") {
    return uniqueIds(mozoId ? [mozoId] : supervisors);
  }

  if (estadoAnterior === "listo" && estadoNuevo === "entregado") {
    return uniqueIds(supervisors);
  }

  if (estadoAnterior === "entregado" && estadoNuevo === "completado") {
    return uniqueIds(admins);
  }

  return [];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json() as DatabaseWebhookPayload<PedidoRecord>;

    if (payload.type !== "UPDATE") {
      return jsonResponse({ ok: true, skipped: "not_update" });
    }

    const pedido = payload.record;
    const pedidoAnterior = payload.old_record;

    if (!pedido?.id || !pedido.tenant_id || !pedido.mesa_id) {
      return jsonResponse({ error: "Payload de pedido inválido." }, 400);
    }

    const estadoAnterior = pedidoAnterior?.estado;
    const estadoNuevo = pedido.estado;

    if (!estadoAnterior || estadoAnterior === estadoNuevo) {
      return jsonResponse({ ok: true, skipped: "estado_sin_cambio" });
    }

    const mesa = await getMesaDetails(createAdminClient(), pedido.mesa_id);
    const notification = buildNotification(
      estadoAnterior,
      estadoNuevo,
      mesa.valor_mesa,
      pedido.nombre_cliente,
    );

    if (!notification) {
      return jsonResponse({ ok: true, skipped: "transicion_no_notificable" });
    }

    const supabase = createAdminClient();
    const recipientIds = await resolveRecipients(
      supabase,
      pedido.tenant_id,
      pedido.mesa_id,
      estadoAnterior,
      estadoNuevo,
    );

    const fcmTokens = await getFcmTokensForUsers(
      supabase,
      pedido.tenant_id,
      recipientIds,
    );

    const sent = await sendFcmPush(fcmTokens, {
      title: notification.title,
      body: notification.body,
      data: {
        tipo: notification.tipo,
        pedido_id: pedido.id,
        mesa_id: pedido.mesa_id,
        tenant_id: pedido.tenant_id,
        estado: estadoNuevo,
      },
    });

    return jsonResponse({
      ok: true,
      pedido_id: pedido.id,
      transicion: `${estadoAnterior} -> ${estadoNuevo}`,
      recipients: recipientIds.length,
      tokens: fcmTokens.length,
      push_sent: sent,
    });
  } catch (error) {
    console.error("notify-estado-pedido:", error);
    const message = error instanceof Error
      ? error.message
      : JSON.stringify(error);
    return jsonResponse({ ok: false, error: message }, 500);
  }
});
