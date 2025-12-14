# How to Create API Endpoints in the Local Server

This guide explains how to add new API endpoints to the Flutter local server.

---

## Architecture Overview

```
lib/local_server/
├── handlers/           # Route handlers (one file per resource)
│   └── accounts_handler.dart
├── services/           # Business logic (optional, for complex operations)
├── server_service.dart # Main server - mounts all handlers
└── network_utils.dart  # Network utilities
```

### Key Concepts

1. **Handler**: A class that defines routes for a specific resource (e.g., accounts, transactions)
2. **Router**: Shelf's routing mechanism - maps HTTP methods + paths to handler functions
3. **Mounting**: Attaching a handler's router to a base path in the main server

---

## Step-by-Step: Creating a New Endpoint

### Step 1: Create the Handler File

Create a new file in `lib/local_server/handlers/`. Name it `<resource>_handler.dart`.

**Example: `lib/local_server/handlers/banks_handler.dart`**

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:totals/data/consts.dart';

/// Handler for bank-related API endpoints
class BanksHandler {
  /// Returns a configured router with all bank routes
  Router get router {
    final router = Router();

    // Define your routes here
    router.get('/', _getBanks);

    return router;
  }

  /// GET /api/banks
  /// Returns all supported banks
  Future<Response> _getBanks(Request request) async {
    try {
      final banks = AppConstants.banks.map((bank) => {
        'id': bank.id,
        'name': bank.name,
        'shortName': bank.shortName,
        'image': bank.image,
      }).toList();

      return Response.ok(
        jsonEncode(banks),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch banks: $e', 500);
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
```

---

### Step 2: Mount the Handler in `server_service.dart`

Open `lib/local_server/server_service.dart` and:

1. **Import the handler** at the top of the file:

```dart
import 'handlers/banks_handler.dart';
```

2. **Mount the handler** in the `startServer()` method, after `final router = Router();`:

```dart
// Mount API handlers
final banksHandler = BanksHandler();
router.mount('/api/banks', banksHandler.router.call);
```

---

### Step 3: Test Your Endpoint

Start the server and test with:
- **Browser**: `http://localhost:8080/api/banks`
- **cURL**: `curl http://localhost:8080/api/banks`

---

## Route Types

### GET - Retrieve data

```dart
router.get('/', _getAllItems);                    // GET /api/items
router.get('/<id>', _getItemById);                // GET /api/items/123
router.get('/<bankId>/<accountNumber>', _getOne); // GET /api/items/1/12345
```

### POST - Create data

```dart
router.post('/', _createItem);  // POST /api/items
```

### PUT - Update data

```dart
router.put('/<id>', _updateItem);  // PUT /api/items/123
```

### DELETE - Remove data

```dart
router.delete('/<id>', _deleteItem);  // DELETE /api/items/123
```

---

## Handling URL Parameters

### Path Parameters

Path parameters are defined with `<paramName>` and passed to your handler:

```dart
router.get('/<id>', _getById);

Future<Response> _getById(Request request, String id) async {
  // `id` is automatically extracted from the URL
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return _errorResponse('Invalid ID', 400);
  }
  // ... fetch and return data
}
```

### Query Parameters

Query parameters are accessed from the request URL:

```dart
// URL: /api/transactions?limit=10&offset=0&type=CREDIT

Future<Response> _getTransactions(Request request) async {
  final queryParams = request.url.queryParameters;
  
  final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
  final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;
  final type = queryParams['type'];  // "CREDIT" or null
  
  // ... use these to filter/paginate data
}
```

---

## Reading Request Body (POST/PUT)

```dart
Future<Response> _createItem(Request request) async {
  try {
    // Read the body as string
    final bodyString = await request.readAsString();
    
    // Parse JSON
    final body = jsonDecode(bodyString) as Map<String, dynamic>;
    
    // Access fields
    final name = body['name'] as String?;
    final amount = body['amount'] as double?;
    
    if (name == null || amount == null) {
      return _errorResponse('Missing required fields', 400);
    }
    
    // ... save and return response
  } catch (e) {
    return _errorResponse('Invalid request body: $e', 400);
  }
}
```

---

## Response Patterns

### Success Response

```dart
return Response.ok(
  jsonEncode({'data': items, 'total': items.length}),
  headers: {'Content-Type': 'application/json'},
);
```

### Error Response

```dart
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
```

### Common Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST (created new resource) |
| 400 | Bad Request | Invalid input/parameters |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Unexpected errors |

---

## Using Repositories

Access data through the existing repositories:

```dart
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/repositories/transaction_repository.dart';

class MyHandler {
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  Future<Response> _getData(Request request) async {
    final accounts = await _accountRepo.getAccounts();
    final transactions = await _transactionRepo.getTransactions();
    // ...
  }
}
```

---

## Using Bank Constants

Access bank information from `AppConstants`:

```dart
import 'package:totals/data/consts.dart';

// Get all banks
final banks = AppConstants.banks;

// Find bank by ID
Bank? getBankById(int id) {
  try {
    return AppConstants.banks.firstWhere((b) => b.id == id);
  } catch (e) {
    return null;
  }
}
```

---

## Complete Handler Template

Copy this template to create new handlers:

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
// Add your imports here

/// Handler for <resource>-related API endpoints
class MyResourceHandler {
  // Add repositories if needed
  // final MyRepository _repo = MyRepository();

  /// Returns a configured router with all routes
  Router get router {
    final router = Router();

    router.get('/', _getAll);
    router.get('/<id>', _getById);
    router.post('/', _create);
    router.put('/<id>', _update);
    router.delete('/<id>', _delete);

    return router;
  }

  /// GET /api/resource
  Future<Response> _getAll(Request request) async {
    try {
      // Get query params
      final queryParams = request.url.queryParameters;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;

      // Fetch data
      // final items = await _repo.getAll();

      // Return response
      return Response.ok(
        jsonEncode({
          'data': [],  // Replace with actual data
          'total': 0,
          'limit': limit,
          'offset': offset,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch: $e', 500);
    }
  }

  /// GET /api/resource/:id
  Future<Response> _getById(Request request, String id) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return _errorResponse('Invalid ID', 400);
      }

      // Fetch single item
      // final item = await _repo.getById(parsedId);

      // if (item == null) {
      //   return _errorResponse('Not found', 404);
      // }

      return Response.ok(
        jsonEncode({}),  // Replace with actual data
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch: $e', 500);
    }
  }

  /// POST /api/resource
  Future<Response> _create(Request request) async {
    try {
      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString) as Map<String, dynamic>;

      // Validate and save
      // await _repo.save(...);

      return Response(
        201,
        body: jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to create: $e', 500);
    }
  }

  /// PUT /api/resource/:id
  Future<Response> _update(Request request, String id) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return _errorResponse('Invalid ID', 400);
      }

      final bodyString = await request.readAsString();
      final body = jsonDecode(bodyString) as Map<String, dynamic>;

      // Update item
      // await _repo.update(parsedId, ...);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to update: $e', 500);
    }
  }

  /// DELETE /api/resource/:id
  Future<Response> _delete(Request request, String id) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return _errorResponse('Invalid ID', 400);
      }

      // Delete item
      // await _repo.delete(parsedId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to delete: $e', 500);
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
```

---

## Checklist for New Endpoints

- [ ] Create handler file in `lib/local_server/handlers/`
- [ ] Define `Router get router` with all routes
- [ ] Implement handler methods for each route
- [ ] Add proper error handling with try/catch
- [ ] Return JSON responses with `Content-Type` header
- [ ] Import handler in `server_service.dart`
- [ ] Mount handler with `router.mount('/api/<path>', handler.router.call)`
- [ ] Test endpoint with browser or cURL