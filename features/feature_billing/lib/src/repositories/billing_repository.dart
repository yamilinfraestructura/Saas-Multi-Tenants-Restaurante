class SuscripcionInfo {
  const SuscripcionInfo({
    required this.planNombre,
    required this.monto,
    required this.moneda,
    required this.fechaFin,
    required this.estado,
  });

  factory SuscripcionInfo.fromJson(Map<String, dynamic> json) {
    return SuscripcionInfo(
      planNombre: json['plan_nombre'] as String,
      monto: (json['monto'] as num).toDouble(),
      moneda: json['moneda'] as String? ?? 'ARS',
      fechaFin: json['fecha_fin'] as String,
      estado: json['estado'] as String,
    );
  }

  final String planNombre;
  final double monto;
  final String moneda;
  final String fechaFin;
  final String estado;
}

abstract class BillingRepository {
  Future<SuscripcionInfo?> getSuscripcionActiva(String tenantId);
}
