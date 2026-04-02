# PharmaFix Project Architecture & Constitution

This document is the **OFFICIAL CONSTITUTION** and architecture guide for **PharmaFix**. All development MUST adhere to these non-negotiable principles.

---

## 1. Core Principles

### 1.1 Business Critical Accuracy
- All financial, inventory, and transaction data MUST be accurate and consistent.
- No operation may result in silent data loss or inconsistency.

### 1.2 Offline-First Operation
- The system MUST operate fully offline.
- All actions MUST be queueable and sync automatically when connection is restored.
- Conflict resolution MUST be deterministic.

### 1.3 Performance First (POS Priority)
- POS operations MUST complete in < 300ms.
- Barcode scanning MUST be instant and not blocked by network.

### 1.4 Simplicity Over Complexity
- UI and workflows MUST be minimal and optimized for speed.
- Avoid unnecessary steps in selling and inventory operations.

---

## 2. Architecture Rules

### 2.1 Modular Design
- The system MUST be divided into independent modules:
  - POS
  - Inventory
  - Suppliers
  - Accounting
  - Reports

### 2.2 Clean Architecture
- Business logic MUST be separated from UI and infrastructure.
- No direct dependency from UI to database.

### 2.3 API Standards
- All APIs MUST be RESTful and versioned.
- All endpoints MUST be authenticated.

---

## 3. Data Integrity & Safety

### 3.1 Transaction Safety
- All financial operations MUST be atomic.
- No partial writes are allowed.

### 3.2 Auditability
- Every critical action MUST be logged:
  - Sales
  - Purchases
  - Edits
  - Deletes

### 3.3 Backup & Recovery
- The system MUST support automatic backup.
- Recovery MUST be possible without data loss.

---

## 4. Inventory Rules

### 4.1 Expiry Management
- Expiry tracking is MANDATORY for all products.
- System MUST alert before expiration.

### 4.2 Stock Accuracy
- Stock levels MUST always reflect real inventory.
- Negative stock is NOT allowed unless explicitly permitted.

### 4.3 Barcode-First System
- All products SHOULD support barcode scanning.
- Manual entry MUST be fallback only.

---

## 5. Financial Rules

### 5.1 Supplier Accounting
- Each supplier MUST have:
  - Balance
  - Debt tracking
  - Payment history

### 5.2 Sales Integrity
- Every sale MUST generate a record and invoice.
- Deleting financial records MUST be restricted.

---

## 6. Roles & Permissions

### 6.1 Role-Based Access Control
- System MUST support roles:
  - Admin
  - Cashier

### 6.2 Permissions
- Cashier:
  - Can sell
  - Cannot edit financial data
- Admin:
  - Full access

---

## 7. UX Rules

### 7.1 Speed is Priority
- Selling flow MUST be achievable in ≤ 3 steps.

### 7.2 Error Prevention
- System MUST prevent:
  - Selling expired products
  - Selling out-of-stock items

---

## 8. Testing & Quality

### 8.1 Test Coverage
- Critical modules MUST have tests:
  - POS
  - Inventory
  - Accounting

### 8.2 Validation
- All inputs MUST be validated at all layers.

---

## 9. Constraints

- No feature may violate offline-first principle.
- No feature may bypass audit logging.
- No feature may compromise performance in POS flow.

---

## 10. Evolution Rules

- Constitution changes MUST be rare and justified.
- Any change MUST evaluate impact on:
  - Data integrity
  - Performance
  - Offline capability
