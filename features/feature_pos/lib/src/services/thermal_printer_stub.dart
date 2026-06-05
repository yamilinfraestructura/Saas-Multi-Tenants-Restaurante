import '../services/thermal_printer_service.dart';

class ThermalPrinterServiceImpl implements ThermalPrinterService {
  @override
  Future<PrinterConfig?> getPrinterConfig() async => null;

  @override
  Future<void> printTicket({
    required String titulo,
    required List<String> lineas,
  }) async {
    throw UnsupportedError('Impresión térmica no disponible en esta plataforma');
  }
}

ThermalPrinterService createThermalPrinterService() =>
    ThermalPrinterServiceImpl();
