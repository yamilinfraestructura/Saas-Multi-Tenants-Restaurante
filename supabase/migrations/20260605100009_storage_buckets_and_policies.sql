-- Migración 09: Storage — Buckets y políticas RLS
-- Fuente: sdd/PLAN/BASE_DE_DATOS/STORAGE/sdd_storage.md

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('tenant_logos', 'tenant_logos', TRUE, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('productos',    'productos',    TRUE, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('avatars',      'avatars',      TRUE, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- BUCKET: tenant_logos
-- ============================================================
CREATE POLICY "tenant_logos_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'tenant_logos');

CREATE POLICY "tenant_logos_tenant_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'tenant_logos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "tenant_logos_tenant_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'tenant_logos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "tenant_logos_tenant_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'tenant_logos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

-- ============================================================
-- BUCKET: productos
-- ============================================================
CREATE POLICY "productos_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'productos');

CREATE POLICY "productos_tenant_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'productos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "productos_tenant_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'productos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "productos_tenant_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'productos'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

-- ============================================================
-- BUCKET: avatars
-- ============================================================
CREATE POLICY "avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "avatars_tenant_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "avatars_tenant_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

CREATE POLICY "avatars_tenant_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);
