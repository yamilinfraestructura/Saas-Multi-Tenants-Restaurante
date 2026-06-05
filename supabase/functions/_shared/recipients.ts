import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const NIVEL_ORDER: Record<string, number> = {
  superadmin: 100,
  admin: 80,
  supervisor: 60,
  cocina: 40,
  bar: 35,
  mozo: 30,
  general: 10,
};

export async function getMesaValor(
  supabase: SupabaseClient,
  mesaId: string,
): Promise<string> {
  const { data, error } = await supabase
    .from("mesas")
    .select("valor_mesa")
    .eq("id", mesaId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data?.valor_mesa ?? "N/A";
}

export async function getMesaDetails(
  supabase: SupabaseClient,
  mesaId: string,
): Promise<{ valor_mesa: string; personal_asignado_id: string | null }> {
  const { data, error } = await supabase
    .from("mesas")
    .select("valor_mesa, personal_asignado_id")
    .eq("id", mesaId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return {
    valor_mesa: data?.valor_mesa ?? "N/A",
    personal_asignado_id: data?.personal_asignado_id ?? null,
  };
}

export async function getUsersByPermissionCodes(
  supabase: SupabaseClient,
  tenantId: string,
  permissionCodes: string[],
): Promise<string[]> {
  if (permissionCodes.length === 0) {
    return [];
  }

  const { data: permisos, error: permError } = await supabase
    .from("permisos_modulo")
    .select("id")
    .in("codigo", permissionCodes);

  if (permError) {
    throw permError;
  }

  const permisoIds = (permisos ?? []).map((row) => row.id as string);
  if (permisoIds.length === 0) {
    return [];
  }

  const { data: asignaciones, error } = await supabase
    .from("asignaciones")
    .select("usuario_id")
    .eq("tenant_id", tenantId)
    .eq("activo", true)
    .in("permiso_modulo_id", permisoIds);

  if (error) {
    throw error;
  }

  return uniqueIds((asignaciones ?? []).map((row) => row.usuario_id as string));
}

export async function getUsersByRoleNiveles(
  supabase: SupabaseClient,
  tenantId: string,
  niveles: string[],
): Promise<string[]> {
  const { data: roles, error: rolesError } = await supabase
    .from("roles_sistema")
    .select("id")
    .in("nivel", niveles);

  if (rolesError) {
    throw rolesError;
  }

  const roleIds = (roles ?? []).map((row) => row.id as string);
  if (roleIds.length === 0) {
    return [];
  }

  const { data: users, error } = await supabase
    .from("usuarios")
    .select("id")
    .eq("tenant_id", tenantId)
    .eq("activo", true)
    .in("rol_id", roleIds);

  if (error) {
    throw error;
  }

  return (users ?? []).map((row) => row.id as string);
}

export async function getUsersAtOrAboveNivel(
  supabase: SupabaseClient,
  tenantId: string,
  minNivel: string,
): Promise<string[]> {
  const minOrder = NIVEL_ORDER[minNivel] ?? 0;
  const allowedNiveles = Object.entries(NIVEL_ORDER)
    .filter(([, order]) => order >= minOrder)
    .map(([nivel]) => nivel);

  return getUsersByRoleNiveles(supabase, tenantId, allowedNiveles);
}

export async function getFcmTokensForUsers(
  supabase: SupabaseClient,
  tenantId: string,
  userIds: string[],
): Promise<string[]> {
  if (userIds.length === 0) {
    return [];
  }

  const { data, error } = await supabase
    .from("usuario_fcm_tokens")
    .select("fcm_token")
    .eq("tenant_id", tenantId)
    .eq("activo", true)
    .in("usuario_id", userIds);

  if (error) {
    throw error;
  }

  return (data ?? []).map((row) => row.fcm_token as string);
}

export function uniqueIds(ids: string[]): string[] {
  return [...new Set(ids.filter(Boolean))];
}
