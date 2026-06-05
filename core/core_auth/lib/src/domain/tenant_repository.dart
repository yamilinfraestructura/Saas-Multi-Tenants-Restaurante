class TenantInfo {
  const TenantInfo({
    required this.id,
    required this.nombre,
    required this.estado,
    this.planActual,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> json) {
    return TenantInfo(
      id: json['id'] as String,
      nombre: json['nombre_negocio'] as String,
      estado: json['estado'] as String,
      planActual: json['plan_actual'] as String?,
    );
  }

  final String id;
  final String nombre;
  final String estado;
  final String? planActual;

  bool get isActivo => estado == 'activo';
  bool get isSuspendido => estado == 'suspendido';
  bool get isInactivo => estado == 'inactivo';
}

abstract class TenantRepository {
  Future<TenantInfo?> getTenantById(String tenantId);
}
