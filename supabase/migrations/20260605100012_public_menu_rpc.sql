-- RPC público para menú QR (clientes anónimos)
CREATE OR REPLACE FUNCTION public.get_public_menu(p_slug TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant tenants%ROWTYPE;
  v_config configuracion_negocio%ROWTYPE;
  v_categorias JSONB;
  v_productos JSONB;
BEGIN
  SELECT * INTO v_tenant
  FROM tenants
  WHERE dominio_slug = p_slug;

  IF NOT FOUND OR v_tenant.estado <> 'activo' THEN
    RETURN jsonb_build_object('error', 'unavailable');
  END IF;

  SELECT * INTO v_config
  FROM configuracion_negocio
  WHERE tenant_id = v_tenant.id;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'nombre_categoria', c.nombre_categoria,
      'posicion', c.posicion,
      'emoji', c.emoji
    ) ORDER BY c.posicion
  ), '[]'::jsonb)
  INTO v_categorias
  FROM categorias c
  WHERE c.tenant_id = v_tenant.id AND c.status = 'activo';

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', p.id,
      'nombre', p.nombre,
      'precio', p.precio,
      'categoria_id', p.categoria_id,
      'img', p.img
    ) ORDER BY p.nombre
  ), '[]'::jsonb)
  INTO v_productos
  FROM productos p
  WHERE p.tenant_id = v_tenant.id AND p.estado = 'activo';

  RETURN jsonb_build_object(
    'tenant', jsonb_build_object(
      'id', v_tenant.id,
      'nombre', COALESCE(v_config.nombre_mostrar, v_tenant.nombre_negocio),
      'logo_url', COALESCE(v_config.logo_menu_url, v_tenant.logo_url),
      'estado', v_tenant.estado
    ),
    'categorias', v_categorias,
    'productos', v_productos
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.create_public_pedido(
  p_tenant_id UUID,
  p_mesa_id UUID,
  p_nombre_cliente TEXT,
  p_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_mesa mesas%ROWTYPE;
  v_pedido_id UUID;
  v_item JSONB;
  v_producto productos%ROWTYPE;
BEGIN
  SELECT * INTO v_mesa
  FROM mesas
  WHERE id = p_mesa_id AND tenant_id = p_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Mesa inválida';
  END IF;

  INSERT INTO pedidos (tenant_id, mesa_id, nombre_cliente, estado)
  VALUES (p_tenant_id, p_mesa_id, p_nombre_cliente, 'pendiente')
  RETURNING id INTO v_pedido_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT * INTO v_producto
    FROM productos
    WHERE id = (v_item ->> 'producto_id')::UUID
      AND tenant_id = p_tenant_id
      AND estado = 'activo';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Producto inválido';
    END IF;

    INSERT INTO pedido_items (
      pedido_id,
      producto_id,
      nombre_item,
      cantidad,
      precio_unitario
    ) VALUES (
      v_pedido_id,
      v_producto.id,
      v_producto.nombre,
      (v_item ->> 'cantidad')::INTEGER,
      (v_item ->> 'precio_unitario')::NUMERIC
    );
  END LOOP;

  UPDATE mesas
  SET estado = 'en_curso', ultimo_pedido = NOW()
  WHERE id = p_mesa_id;

  RETURN v_pedido_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_menu(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_public_pedido(UUID, UUID, TEXT, JSONB) TO anon, authenticated;
