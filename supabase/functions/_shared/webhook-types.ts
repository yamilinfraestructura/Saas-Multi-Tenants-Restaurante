export type WebhookEventType = "INSERT" | "UPDATE" | "DELETE";

export interface DatabaseWebhookPayload<T = Record<string, unknown>> {
  type: WebhookEventType;
  table: string;
  schema: string;
  record: T | null;
  old_record: T | null;
}

export interface PedidoRecord {
  id: string;
  tenant_id: string;
  mesa_id: string;
  nombre_cliente: string;
  estado: string;
  total: number;
  fecha_creacion: string;
}
