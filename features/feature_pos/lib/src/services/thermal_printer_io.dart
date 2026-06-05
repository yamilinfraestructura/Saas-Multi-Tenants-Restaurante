import 'dart:io';

import 'package:core_network/core_network.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'thermal_printer_service.dart';

class ThermalPrinterServiceImpl implements ThermalPrinterService {
  ThermalPrinterServiceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<PrinterConfig?> getPrinterConfig() async {
    final tenantId =
        _client.auth.currentUser?.appMetadata['tenant_id'] as String?;
    if (tenantId == null) {
      return null;
    }

    final data = await _client
        .from('configuracion_negocio')
        .select('impresora_activada, impresora_ip, impresora_puerto')
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return PrinterConfig.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> printTicket({
    required String titulo,
    required List<String> lineas,
  }) async {
    final config = await getPrinterConfig();
    if (config == null || !config.isConfigured) {
      throw StateError('Impresora no configurada en el panel admin');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(titulo,
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(generator.hr());
    for (final linea in lineas) {
      bytes.addAll(generator.text(linea));
    }
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final socket = await Socket.connect(config.ip, config.puerto,
        timeout: const Duration(seconds: 5));
    try {
      socket.add(bytes);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }
}

ThermalPrinterService createThermalPrinterService() {
  return ThermalPrinterServiceImpl(locator<SupabaseClient>());
}
