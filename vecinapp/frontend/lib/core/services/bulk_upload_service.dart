import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:vecinapp/core/models/community.dart';
import 'package:vecinapp/core/models/unit.dart';
import 'package:vecinapp/core/services/community_service.dart';
import 'package:vecinapp/core/services/unit_service.dart';

class BulkUploadService {
  final CommunityService _communityService = CommunityService();
  final UnitService _unitService = UnitService();

  Future<Map<String, dynamic>> processExcel(Uint8List fileBytes) async {
    var excel = Excel.decodeBytes(fileBytes);
    int communitiesCreated = 0;
    int unitsCreated = 0;
    List<String> errors = [];

    // Asumimos que la data está en la primera hoja
    var table = excel.tables[excel.tables.keys.first];
    if (table == null) {
      return {'success': false, 'message': 'No se encontró hoja de cálculo'};
    }

    // Agrupar filas por nombre de comunidad para crear la comunidad una sola vez
    Map<String, List<List<Data?>>> communityRows = {};

    // Empezamos desde la fila 1 (saltando cabecera)
    for (var i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.isEmpty) continue;
      
      // Asumimos columna 0 es Nombre Comunidad
      var communityName = _getValue(row[0]);
      if (communityName == null || communityName.toString().isEmpty) continue;

      if (!communityRows.containsKey(communityName)) {
        communityRows[communityName.toString()] = [];
      }
      communityRows[communityName.toString()]!.add(row);
    }

    // Procesar cada comunidad
    for (var entry in communityRows.entries) {
      String commName = entry.key;
      List<List<Data?>> rows = entry.value;
      
      try {
        // Tomamos los datos de la comunidad de la primera fila del grupo
        var firstRow = rows.first;
        
        // Mapeo de columnas (Asunción basada en requerimiento)
        // 0: Nombre, 1: Dirección, 2: Comuna, 3: Región, 4: Lat, 5: Lng, 
        // 6: Constructora, 7: Inmobiliaria, 8: Email, 9: Teléfono
        
        Community newCommunity = Community(
          id: '', // Backend genera ID
          name: commName,
          address: _getValue(firstRow[1])?.toString() ?? '',
          comuna: _getValue(firstRow[2])?.toString() ?? '',
          region: _getValue(firstRow[3])?.toString() ?? '',
          isActive: true,
          latitude: double.tryParse(_getValue(firstRow[4])?.toString() ?? ''),
          longitude: double.tryParse(_getValue(firstRow[5])?.toString() ?? ''),
          constructora: _getValue(firstRow[6])?.toString(),
          inmobiliaria: _getValue(firstRow[7])?.toString(),
          contactEmail: _getValue(firstRow[8])?.toString(),
          contactPhone: _getValue(firstRow[9])?.toString(),
        );

        // Crear Comunidad
        Community createdComm = await _communityService.createCommunity(newCommunity);
        communitiesCreated++;

        // Crear Unidades para esta comunidad
        for (var row in rows) {
          // Mapeo de columnas de Unidad (continuación)
          // 10: Nombre/N°, 11: Piso, 12: Tipo, 13: Estado, 14: M2, 15: Alicuota
          
          var unitName = _getValue(row[10])?.toString();
          if (unitName == null || unitName.isEmpty) continue; // Si no hay unidad, saltamos

          Unit newUnit = Unit(
            id: '',
            communityId: createdComm.id,
            name: unitName,
            floor: int.tryParse(_getValue(row[11])?.toString() ?? '1') ?? 1,
            type: _getValue(row[12])?.toString() ?? 'Departamento',
            status: _getValue(row[13])?.toString() ?? 'Disponible',
            m2: double.tryParse(_getValue(row[14])?.toString() ?? '0') ?? 0.0,
            alicuota: double.tryParse(_getValue(row[15])?.toString() ?? '0') ?? 0.0,
          );

          await _unitService.createUnit(newUnit);
          unitsCreated++;
        }

      } catch (e) {
        print("Error procesando comunidad $commName: $e");
        errors.add("Error en comunidad '$commName': $e");
      }
    }

    return {
      'success': true,
      'communities': communitiesCreated,
      'units': unitsCreated,
      'errors': errors
    };
  }

  dynamic _getValue(Data? data) {
    return data?.value;
  }
}
