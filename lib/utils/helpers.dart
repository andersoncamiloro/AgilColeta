import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String generateId() => _uuid.v4();

String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

String formatDateTime(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);

String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

String formatLitros(double litros) =>
    '${NumberFormat('#,##0.0', 'pt_BR').format(litros)} L';

String formatTemp(double temp) => '${temp.toStringAsFixed(1)}°C';

String formatLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return 'Sem localização';
  return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}
