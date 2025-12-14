import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:totals/data/consts.dart';

/// Handler for bank-related API endpoints
class BanksHandler {
  /// Returns a configured router with all bank routes
  Router get router {
    final router = Router();

    // GET /api/banks - List all supported banks
    router.get('/', _getBanks);

    // GET /api/banks/<id> - Get single bank by ID
    router.get('/<id>', _getBankById);

    return router;
  }

  /// GET /api/banks
  /// Returns all supported banks
  Future<Response> _getBanks(Request request) async {
    try {
      final banks = AppConstants.banks
          .map((bank) => {
                'id': bank.id,
                'name': bank.name,
                'shortName': bank.shortName,
                'codes': bank.codes,
                'image': bank.image,
              })
          .toList();

      return Response.ok(
        jsonEncode(banks),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch banks: $e', 500);
    }
  }

  /// GET /api/banks/:id
  /// Returns a single bank by ID
  Future<Response> _getBankById(Request request, String id) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return _errorResponse('Invalid bank ID', 400);
      }

      final bank = AppConstants.banks.cast<Bank?>().firstWhere(
            (b) => b!.id == parsedId,
            orElse: () => null,
          );

      if (bank == null) {
        return _errorResponse('Bank not found', 404);
      }

      return Response.ok(
        jsonEncode({
          'id': bank.id,
          'name': bank.name,
          'shortName': bank.shortName,
          'codes': bank.codes,
          'image': bank.image,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch bank: $e', 500);
    }
  }

  /// Helper to create standardized error responses
  Response _errorResponse(String message, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode({
        'error': true,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
