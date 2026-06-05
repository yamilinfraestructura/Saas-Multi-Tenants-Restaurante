-- Migración 10: Tokens FCM por usuario (requerido por sdd_webhooks.md)
-- Permite a las Edge Functions enviar push notifications a dispositivos registrados.

CREATE TABLE usuario_fcm_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usuario_id   VARCHAR(128) NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fcm_token    TEXT NOT NULL,
    platform     VARCHAR(20) CHECK (platform IN ('android', 'ios', 'web')),
    activo       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_usuario_fcm_token UNIQUE (tenant_id, usuario_id, fcm_token)
);

COMMENT ON TABLE usuario_fcm_tokens IS
    'Tokens FCM registrados por dispositivo. Flutter los upserta al iniciar sesión.';

CREATE INDEX idx_fcm_tokens_usuario ON usuario_fcm_tokens(usuario_id);
CREATE INDEX idx_fcm_tokens_tenant  ON usuario_fcm_tokens(tenant_id);
CREATE INDEX idx_fcm_tokens_activo  ON usuario_fcm_tokens(activo);

ALTER TABLE usuario_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fcm_tokens_select"
  ON usuario_fcm_tokens FOR SELECT
  USING (
    tenant_id = public.get_tenant_id()
    AND (
      public.tiene_nivel_minimo('supervisor')
      OR usuario_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "fcm_tokens_write_own"
  ON usuario_fcm_tokens FOR ALL
  USING (
    tenant_id = public.get_tenant_id()
    AND usuario_id = auth.uid()::TEXT
  )
  WITH CHECK (
    tenant_id = public.get_tenant_id()
    AND usuario_id = auth.uid()::TEXT
  );

CREATE TRIGGER trg_fcm_tokens_updated_at
BEFORE UPDATE ON usuario_fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
