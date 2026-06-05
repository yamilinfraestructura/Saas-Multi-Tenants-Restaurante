-- Migración 11: Database Webhooks → Edge Functions (FASE 1 checklist)
-- Fuente: sdd/PLAN/BASE_DE_DATOS/WEB_HOOKS/sdd_webhooks.md
-- wh_pedidos_insert → notify-nuevo-pedido
-- wh_pedidos_estado_update → notify-estado-pedido

DROP TRIGGER IF EXISTS wh_pedidos_insert ON public.pedidos;
CREATE TRIGGER wh_pedidos_insert
AFTER INSERT ON public.pedidos
FOR EACH ROW
EXECUTE FUNCTION supabase_functions.http_request(
  'https://rojczcqkxdwjmxxxfdau.supabase.co/functions/v1/notify-nuevo-pedido',
  'POST',
  '{"Content-Type":"application/json"}',
  '{}',
  '5000'
);

DROP TRIGGER IF EXISTS wh_pedidos_estado_update ON public.pedidos;
CREATE TRIGGER wh_pedidos_estado_update
AFTER UPDATE ON public.pedidos
FOR EACH ROW
EXECUTE FUNCTION supabase_functions.http_request(
  'https://rojczcqkxdwjmxxxfdau.supabase.co/functions/v1/notify-estado-pedido',
  'POST',
  '{"Content-Type":"application/json"}',
  '{}',
  '5000'
);
