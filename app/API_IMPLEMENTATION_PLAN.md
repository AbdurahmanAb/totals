# API Implementation Plan for Totals Local Server

This document outlines the API endpoints to be implemented in the Flutter app's local server to serve data to the `totals-web` frontend.

---

## Overview

The Flutter app runs a local HTTP server using **Shelf** that:
1. Serves the web app's static files
2. Provides REST API endpoints for data access

The web app (`totals-web`) will consume these endpoints to display accounts, transactions, analytics, and more.

---

## Current Architecture

### Existing Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `ServerService` | `lib/local_server/server_service.dart` | Main Shelf server with routing |
| `Account` model | `lib/models/account.dart` | Account data model |
| `Transaction` model | `lib/models/transaction.dart` | Transaction data model |
| `AccountRepository` | `lib/repositories/account_repository.dart` | Account CRUD operations |
| `TransactionRepository` | `lib/repositories/transaction_repository.dart` | Transaction CRUD operations |
| `AppConstants.banks` | `lib/data/consts.dart` | Bank definitions (id, name, image) |
| Summary models | `lib/models/summary_models.dart` | `BankSummary`, `AccountSummary`, `AllSummary` |

### Empty Folders (To Be Used)

- `lib/local_server/handlers/` - Route handlers for each endpoint group
- `lib/local_server/services/` - Business logic and data aggregation

---

## Endpoints to Implement

### Priority Levels

- **P0**: Critical for basic functionality
- **P1**: Important for dashboard/charts
- **P2**: Enhanced analytics features
- **P3**: Nice-to-have features

---

### P0: Core Data Endpoints

#### 1. `GET /api/banks`

Returns the list of supported banks.

**Source**: `AppConstants.banks`

**Response**:
```json
[
  {
    "id": 1,
    "name": "Commercial Bank Of Ethiopia",
    "shortName": "CBE",
    "image": "assets/images/cbe.png"
  },
  {
    "id": 2,
    "name": "Awash Bank",
    "shortName": "Awash",
    "image": "assets/images/awash.png"
  }
]
```

**Handler File**: `lib/local_server/handlers/banks_handler.dart`

---

#### 2. `GET /api/accounts`

Returns all accounts with bank information enriched.

**Source**: `AccountRepository.getAccounts()` + bank name lookup

**Response**:
```json
[
  {
    "accountNumber": "1234567890",
    "bank": 1,
    "bankName": "Commercial Bank Of Ethiopia",
    "bankShortName": "CBE",
    "bankImage": "assets/images/cbe.png",
    "balance": 24500.80,
    "accountHolderName": "John Doe",
    "settledBalance": 24000.00,
    "pendingCredit": 500.80
  }
]
```

**Handler File**: `lib/local_server/handlers/accounts_handler.dart`

---

#### 3. `GET /api/accounts/:bankId/:accountNumber`

Returns a single account by bank ID and account number.

**Response**: Same shape as single item from `/api/accounts`

**Handler File**: `lib/local_server/handlers/accounts_handler.dart`

---

#### 4. `GET /api/transactions`

Returns transactions with pagination and filtering support.

**Source**: `TransactionRepository.getTransactions()` + filtering

**Query Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `bankId` | int | Filter by bank ID |
| `type` | string | Filter by `CREDIT` or `DEBIT` |
| `status` | string | Filter by `PENDING`, `CLEARED`, `SYNCED` |
| `limit` | int | Number of results (default: 20) |
| `offset` | int | Pagination offset (default: 0) |
| `from` | string | Start date (ISO 8601) |
| `to` | string | End date (ISO 8601) |

**Response**:
```json
{
  "data": [
    {
      "amount": -9.99,
      "reference": "Spotify Premium",
      "creditor": "Spotify Ltd",
      "receiver": null,
      "time": "2024-01-24T10:23:00Z",
      "status": "CLEARED",
      "currentBalance": "24490.81",
      "bankId": 1,
      "bankName": "CBE",
      "type": "DEBIT",
      "transactionLink": null,
      "accountNumber": "1234"
    }
  ],
  "total": 150,
  "limit": 20,
  "offset": 0
}
```

**Handler File**: `lib/local_server/handlers/transactions_handler.dart`

---

### P1: Summary & Dashboard Endpoints

#### 5. `GET /api/summary`

Returns aggregated summary across all accounts.

**Source**: Compute from `AccountRepository` and `TransactionRepository`

**Response**:
```json
{
  "totalBalance": 86400.00,
  "totalCredit": 150000.00,
  "totalDebit": 63600.00,
  "accountCount": 5,
  "bankCount": 4,
  "transactionCount": 243
}
```

**Handler File**: `lib/local_server/handlers/summary_handler.dart`

---

#### 6. `GET /api/summary/by-bank`

Returns summary grouped by bank.

**Response**:
```json
[
  {
    "bankId": 1,
    "bankName": "CBE",
    "totalBalance": 24500.80,
    "totalCredit": 50000.00,
    "totalDebit": 25499.20,
    "accountCount": 2
  }
]
```

**Handler File**: `lib/local_server/handlers/summary_handler.dart`

---

#### 7. `GET /api/analytics/networth`

Returns balance history over time for the Net Worth chart.

**Query Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `timeframe` | string | `1W`, `1M`, `3M`, `1Y`, `ALL` |
| `bankId` | int | (Optional) Filter by specific bank |

**Response**:
```json
{
  "timeframe": "1M",
  "data": [
    { "date": "2024-01-01", "value": 12000 },
    { "date": "2024-01-08", "value": 14500 },
    { "date": "2024-01-15", "value": 13800 },
    { "date": "2024-01-22", "value": 16200 }
  ],
  "change": {
    "amount": 4200,
    "percentage": 35.0
  }
}
```

**Implementation Note**: This requires computing running balances from transaction history. May need to track balance snapshots or compute from `currentBalance` field.

**Handler File**: `lib/local_server/handlers/analytics_handler.dart`

---

### P2: Analytics Endpoints

#### 8. `GET /api/analytics/spending`

Returns spending breakdown by category/creditor for the Spending Stats widget.

**Query Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `timeframe` | string | `1W`, `1M`, `3M`, `1Y` |

**Response**:
```json
{
  "total": 2100,
  "categories": [
    { "name": "Food", "value": 400, "color": "#f87171" },
    { "name": "Rent", "value": 1200, "color": "#60a5fa" },
    { "name": "Travel", "value": 300, "color": "#fbbf24" },
    { "name": "Subscriptions", "value": 200, "color": "#a3a3a3" }
  ]
}
```

**Implementation Note**: May need to categorize transactions by creditor name patterns or add a category field.

**Handler File**: `lib/local_server/handlers/analytics_handler.dart`

---

#### 9. `GET /api/transactions/stats`

Returns transaction statistics for pie charts on the Transactions page.

**Response**:
```json
{
  "byAccount": [
    { "bankId": 1, "name": "CBE", "volume": 12000, "count": 45 },
    { "bankId": 2, "name": "Awash", "volume": 8000, "count": 32 },
    { "bankId": 6, "name": "Telebirr", "volume": 3000, "count": 18 }
  ],
  "totals": {
    "totalVolume": 23000,
    "totalCount": 95
  }
}
```

**Handler File**: `lib/local_server/handlers/transactions_handler.dart`

---

### P3: People/Contacts Endpoints

#### 10. `GET /api/people`

Returns aggregated statistics by creditor/receiver for the People page.

**Query Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search by name |
| `limit` | int | Number of results |
| `offset` | int | Pagination offset |

**Response**:
```json
{
  "data": [
    {
      "name": "Anna",
      "initials": "AN",
      "totalAmount": 15240,
      "transactionCount": 12,
      "lastTransaction": "Received $200",
      "lastTransactionType": "CREDIT",
      "lastTransactionDate": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 25
}
```

**Implementation Note**: Aggregate by unique `creditor` and `receiver` fields from transactions.

**Handler File**: `lib/local_server/handlers/people_handler.dart`

---

#### 11. `GET /api/people/top`

Returns top 3 people by transaction volume (for leaderboard/quick transfer widget).

**Response**:
```json
[
  { "rank": 1, "name": "Anna", "initials": "AN", "totalAmount": 15240 },
  { "rank": 2, "name": "Mark", "initials": "MA", "totalAmount": 8500 },
  { "rank": 3, "name": "Sia", "initials": "SI", "totalAmount": 6200 }
]
```

**Handler File**: `lib/local_server/handlers/people_handler.dart`

---

## File Structure

After implementation, the `local_server` folder should look like:

```
lib/local_server/
├── handlers/
│   ├── accounts_handler.dart      # /api/accounts endpoints
│   ├── analytics_handler.dart     # /api/analytics/* endpoints
│   ├── banks_handler.dart         # /api/banks endpoint
│   ├── people_handler.dart        # /api/people endpoints
│   ├── summary_handler.dart       # /api/summary endpoints
│   └── transactions_handler.dart  # /api/transactions endpoints
├── services/
│   ├── analytics_service.dart     # Net worth, spending calculations
│   └── people_service.dart        # Creditor/receiver aggregation
├── network_utils.dart
├── server_service.dart            # Main router (updated)
└── server_test_screen.dart
```

---

## Implementation Phases

### Phase 1: Core Endpoints (P0)

**Estimated Time**: 2-3 hours

1. Create `banks_handler.dart`
   - Implement `GET /api/banks`

2. Create `accounts_handler.dart`
   - Implement `GET /api/accounts`
   - Implement `GET /api/accounts/:bankId/:accountNumber`

3. Create `transactions_handler.dart`
   - Implement `GET /api/transactions` with pagination/filtering

4. Update `server_service.dart`
   - Register new route handlers

### Phase 2: Summary & Dashboard (P1)

**Estimated Time**: 2-3 hours

1. Create `summary_handler.dart`
   - Implement `GET /api/summary`
   - Implement `GET /api/summary/by-bank`

2. Create `analytics_handler.dart`
   - Implement `GET /api/analytics/networth`

3. Create `analytics_service.dart`
   - Net worth calculation logic

### Phase 3: Enhanced Analytics (P2)

**Estimated Time**: 2-3 hours

1. Add to `analytics_handler.dart`
   - Implement `GET /api/analytics/spending`

2. Add to `transactions_handler.dart`
   - Implement `GET /api/transactions/stats`

### Phase 4: People Feature (P3)

**Estimated Time**: 1-2 hours

1. Create `people_handler.dart`
   - Implement `GET /api/people`
   - Implement `GET /api/people/top`

2. Create `people_service.dart`
   - Creditor/receiver aggregation logic

---

## Frontend Integration

After implementing the API, update `totals-web` to:

1. Create an API client service (`src/lib/api.ts`)
2. Replace mock data in components with API calls
3. Add loading states and error handling

### Example API Client

```typescript
// src/lib/api.ts
const API_BASE = 'http://localhost:8080/api';

export const api = {
  async getAccounts() {
    const res = await fetch(`${API_BASE}/accounts`);
    return res.json();
  },
  
  async getTransactions(params?: { limit?: number; offset?: number; bankId?: number }) {
    const query = new URLSearchParams(params as any).toString();
    const res = await fetch(`${API_BASE}/transactions?${query}`);
    return res.json();
  },
  
  // ... other methods
};
```

---

## Testing

### Manual Testing

Use the existing `server_test_screen.dart` or tools like:
- Browser: `http://localhost:8080/api/accounts`
- cURL: `curl http://localhost:8080/api/transactions?limit=5`
- Postman/Insomnia

### Automated Testing

Consider adding tests in `test/` folder:
- `test/local_server/handlers/accounts_handler_test.dart`
- `test/local_server/handlers/transactions_handler_test.dart`

---

## Notes & Considerations

### CORS

CORS middleware is already implemented in `server_service.dart`. All origins are allowed (`*`) for local development.

### Error Handling

Standardize error responses:

```json
{
  "error": true,
  "message": "Account not found",
  "code": "NOT_FOUND"
}
```

### Performance

- Add database indexes (already done in `database_helper.dart`)
- Consider caching for analytics endpoints
- Paginate large result sets

### Security

For local-only server, current setup is fine. If exposing to network:
- Consider authentication
- Validate all input parameters
- Limit request rates

---

## Checklist

- [x] **Phase 1**: Core Endpoints ✅
  - [x] `GET /api/banks` - `handlers/banks_handler.dart`
  - [x] `GET /api/banks/:id` - `handlers/banks_handler.dart`
  - [x] `GET /api/accounts` - `handlers/accounts_handler.dart`
  - [x] `GET /api/accounts/:bankId/:accountNumber` - `handlers/accounts_handler.dart`
  - [x] `GET /api/transactions` (with filtering & pagination) - `handlers/transactions_handler.dart`
  - [x] Update `server_service.dart` routing

- [x] **Phase 2**: Summary & Dashboard ✅
  - [x] `GET /api/summary` - `handlers/summary_handler.dart`
  - [x] `GET /api/summary/by-bank` - `handlers/summary_handler.dart`
  - [x] `GET /api/summary/by-account` - `handlers/summary_handler.dart`
  - [ ] `GET /api/analytics/networth`

- [x] **Phase 3**: Enhanced Analytics (Partial) ✅
  - [ ] `GET /api/analytics/spending`
  - [x] `GET /api/transactions/stats` - `handlers/transactions_handler.dart`

- [ ] **Phase 4**: People Feature
  - [ ] `GET /api/people`
  - [ ] `GET /api/people/top`

- [ ] **Frontend Integration**
  - [ ] Create API client in `totals-web`
  - [ ] Replace mock data with API calls
  - [ ] Add loading/error states