/// Parses GS1 DataMatrix barcodes commonly found on pharmaceutical packaging.
///
/// Supported Application Identifiers:
///   01 - GTIN (14 digits, fixed length)
///   02 - GTIN of contained trade items (14 digits, fixed length)
///   10 - Batch/Lot Number (variable, up to 20 chars)
///   11 - Manufacturing Date (YYMMDD, fixed 6 digits)
///   17 - Expiry Date (YYMMDD, fixed 6 digits)
///   21 - Serial Number (variable, up to 20 chars)
///   37 - Count of trade items (variable, up to 8 digits)
class GS1ParserService {
  static const String _gs = '\u001D'; // ASCII 29 Group Separator

  static const Map<String, int> _fixedLengthAIs = {
    '01': 14,
    '02': 14,
    '11': 6,
    '17': 6,
  };

  static const Set<String> _variableLengthAIs = {'10', '21', '37'};

  static final List<String> _knownAIs = [
    ..._fixedLengthAIs.keys,
    ..._variableLengthAIs,
  ];

  GS1Data? parse(String raw) {
    if (raw.isEmpty) return null;

    var data = raw;

    // Strip symbology identifiers
    if (data.startsWith(']d2') ||
        data.startsWith(']C1') ||
        data.startsWith(']e0') ||
        data.startsWith(']Q3')) {
      data = data.substring(3);
    }

    String? gtin;
    String? batchNumber;
    DateTime? expiryDate;
    DateTime? manufacturingDate;
    String? serialNumber;
    int? count;

    int pos = 0;
    while (pos < data.length) {
      if (data[pos] == _gs) {
        pos++;
        continue;
      }

      String? matchedAI;
      for (final ai in _knownAIs) {
        if (pos + ai.length <= data.length &&
            data.substring(pos, pos + ai.length) == ai) {
          matchedAI = ai;
          break;
        }
      }

      if (matchedAI == null) {
        pos++;
        continue;
      }

      pos += matchedAI.length;

      if (_fixedLengthAIs.containsKey(matchedAI)) {
        final len = _fixedLengthAIs[matchedAI]!;
        if (pos + len > data.length) break;
        final value = data.substring(pos, pos + len);
        pos += len;

        switch (matchedAI) {
          case '01':
          case '02':
            gtin = value;
            break;
          case '11':
            manufacturingDate = _parseGS1Date(value);
            break;
          case '17':
            expiryDate = _parseGS1Date(value);
            break;
        }
      } else {
        final gsIndex = data.indexOf(_gs, pos);
        final end = gsIndex == -1 ? data.length : gsIndex;
        final value = data.substring(pos, end);
        pos = end;

        switch (matchedAI) {
          case '10':
            batchNumber = value;
            break;
          case '21':
            serialNumber = value;
            break;
          case '37':
            count = int.tryParse(value);
            break;
        }
      }
    }

    if (gtin == null &&
        batchNumber == null &&
        expiryDate == null &&
        manufacturingDate == null &&
        serialNumber == null) {
      return null;
    }

    return GS1Data(
      gtin: gtin,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      manufacturingDate: manufacturingDate,
      serialNumber: serialNumber,
      count: count,
    );
  }

  /// Parses YYMMDD into a DateTime.
  /// Day 00 means "last day of the month" per GS1 spec.
  DateTime? _parseGS1Date(String yymmdd) {
    if (yymmdd.length != 6) return null;
    final yy = int.tryParse(yymmdd.substring(0, 2));
    final mm = int.tryParse(yymmdd.substring(2, 4));
    final dd = int.tryParse(yymmdd.substring(4, 6));
    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12) return null;

    final year = yy <= 49 ? 2000 + yy : 1900 + yy;

    if (dd == 0) {
      final lastDay = DateTime(year, mm + 1, 0).day;
      return DateTime(year, mm, lastDay);
    }

    return DateTime(year, mm, dd);
  }
}

class GS1Data {
  final String? gtin;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? manufacturingDate;
  final String? serialNumber;
  final int? count;

  const GS1Data({
    this.gtin,
    this.batchNumber,
    this.expiryDate,
    this.manufacturingDate,
    this.serialNumber,
    this.count,
  });

  bool get hasAnyField =>
      gtin != null ||
      batchNumber != null ||
      expiryDate != null ||
      manufacturingDate != null ||
      serialNumber != null;

  @override
  String toString() =>
      'GS1Data(gtin: $gtin, batch: $batchNumber, exp: $expiryDate, '
      'mfg: $manufacturingDate, sn: $serialNumber, count: $count)';
}
