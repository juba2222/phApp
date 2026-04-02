# POS Transaction: Sequence & Rollback

This sequence diagram illustrates the interaction between the POS UI, logic layer, and database for a secure pharmacy sale as specified in `SPEC_003_POS_Transaction_Flow.md`.

```mermaid
sequenceDiagram
    participant UI as POS Terminal UI
    participant L as Sales Logic (BLoC)
    participant DB as SQLite / Local DB
    
    UI->>L: Scan Barcode
    L->>DB: Search for Product & Batches (Order by Expiry ASC)
    DB-->>L: Product Data + Earliest Batch
    Note over L: Apply FEFO (First Expiry, First Out)
    L-->>UI: Add to Invoice Draft (expiry_date shown)
    
    UI->>L: Finish Sale (CASH/DEBT)
    L->>DB: START TRANSACTION (Atomic Save)
    
    rect rgb(230, 245, 255)
        Note over DB: Step 1: Insert Invoice
        Note over DB: Step 2: Insert Items per Batch
        Note over DB: Step 3: Decrement Batch Quantities
        Note over DB: Step 4: Add Stock Movement Logs
    end

    alt Database Error (e.g. Constraint Violation)
        DB-->>L: Transaction Error
        L->>DB: ROLLBACK (Undo everything)
        L-->>UI: Error: Sale Failed / Data Reverted
    else Success
        DB-->>L: COMMIT Success
        L-->>UI: Print Invoice + Clear Screen
    end
```
