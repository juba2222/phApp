# Specification: Domain & Data Model (SPEC_002 - Improved)

## 1. Core Entities Definition (Schema v1.1)

### 1.1 Product
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Unique product identifier. |
| `name` | String | NOT NULL | Commercial name of the drug. |
| `barcode` | String | UNIQUE | Global identification. |
| `base_price` | Decimal(12,4) | NOT NULL | Purchase price from supplier. |
| `sell_price` | Decimal(12,4) | NOT NULL | Current retail price. |
| `min_stock` | Int | DEFAULT 0 | Threshold for low stock alerts. |

### 1.2 Batch (Expiry-Based Inventory)
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Internal batch unique ID. |
| `product_id`| UUID | FK | `ON DELETE RESTRICT` |
| `batch_num` | String | NOT NULL | Manufacturer batch number. |
| `expiry_date`| Date | NOT NULL | Expiry date (used for FEFO). |
| `quantity` | Int | CHECK (>=0) | Current quantity in this batch. |

### 1.3 Invoice (Sales)
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Invoice Unique ID. |
| `customer_id`| UUID | FK (NULL OK) | Mandatory if payment_type == DEBT. |
| `total_amt` | Decimal(12,4) | NOT NULL | Sum of all items. |
| `payment_type`| Enum | NOT NULL | CASH, BANK, DEBT. |
| `status` | Enum | NOT NULL | PENDING, PARTIAL_PAID, COMPLETED, CANCELED. |
| `created_at` | DateTime | DEFAULT NOW| Transaction timestamp. |

### 1.4 InvoiceItem (Split Batch Support)
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `invoice_id` | UUID | FK | `ON DELETE CASCADE` |
| `product_id` | UUID | FK | `ON DELETE RESTRICT` |
| `batch_id` | UUID | FK | Specific batch record. |
| `qty` | Int | NOT NULL | Quantity from this specific batch. |
| `price_at_sale`| Decimal(12,4)| NOT NULL | To preserve historical accuracy. |

### 1.5 Debt (Accounting)
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Unique Debt ID. |
| `customer_id`| UUID | FK | `ON DELETE RESTRICT` |
| `invoice_id` | UUID | FK | Parent transaction. |
| `amount_total`| Decimal(12,4)| NOT NULL | Original debt amount. |
| `amount_paid` | Decimal(12,4)| DEFAULT 0 | Sum of all partial payments. |
| `rem_balance` | Decimal(12,4)| CALCULATED | `amount_total - amount_paid`. |
| `due_date` | Date | NULL | When the debt should be settled. |

### 1.6 StockMovement (Audit & Reconciliation)
| Field | Type | Constraint | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Unique Movement ID. |
| `type` | Enum | NOT NULL | SALE, PURCHASE, RETURN, ADJUSTMENT. |
| `product_id` | UUID | FK | Impacted product. |
| `batch_id` | UUID | FK | Impacted batch. |
| `qty_change` | Int | NOT NULL | Positive (+) or Negative (-). |
| `ref_id` | UUID | NOT NULL | Link to Invoice or Purchase ID. |
| `performed_by`| UUID | FK | User ID (Staff/Admin). |

## 2. Advanced Business Rules

### 2.1 Smart FEFO Auto-Split Logic
- **Rule**: If a sale requires $N$ units of a product, and the nearest expiry **Batch A** only has $M < N$ units:
  1. System automatically allocates all $M$ units from **Batch A**.
  2. System searches for the next nearest expiry **Batch B**.
  3. System allocates $N - M$ units from **Batch B**.
  4. Separate `InvoiceItem` records are created for each batch used.
  
### 2.2 Reversal & Inventory Restoration
- **Rule**: When an invoice status is changed to **CANCELED**:
  1. For each `InvoiceItem`, retrieve the `batch_id`.
  2. Create a `StockMovement` of type **RETURN** with positive quantity.
  3. Increment the quantity of the original **Batch** record.
  4. Void any linked **Debt** records.

### 2.3 Partial Payments Rules
- A **Debt** status is updated to `COMPLETED` only when `amount_paid == amount_total`.
- If `amount_paid > 0` but less than total, the parent **Invoice** status must be `PARTIAL_PAID`.

## 3. Technical Constraints (Architecture Consistency)
- **Precision**: All financial fields MUST use `Decimal`/`FixedPoint` to prevent floating-point errors (Cents/Fills accuracy).
- **Offline-First Integration**: Using **SQLite** with **Drift** or **Floor** for Flutter.
- **Integrity**: `ON DELETE RESTRICT` is mandatory for core entities (Products, Customers, Suppliers) to prevent data dangling.
