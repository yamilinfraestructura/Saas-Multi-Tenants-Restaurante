class PrinterConfig {
  const PrinterConfig({
    required this.activada,
    this.ip,
    this.puerto = 9100,
  });

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      activada: json['impresora_activada'] as bool? ?? false,
      ip: json['impresora_ip'] as String?,
      puerto: json['impresora_puerto'] as int? ?? 9100,
    );
  }

  final bool activada;
  final String? ip;
  final int puerto;

  bool get isConfigured => activada && ip != null && ip!.isNotEmpty;
}

abstract class ThermalPrinterService {
  Future<PrinterConfig?> getPrinterConfig();
  Future<void> printTicket({
    required String titulo,
    required List<String> lineas,
  });
}
