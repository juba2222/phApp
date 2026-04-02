# POS Logic Flow: Sales & Cancellation

This flowchart defines the business logic for the POS module as specified in `SPEC_001_POS_Sales.md`.

```mermaid
graph TD
    A[Start Sales Process] --> B[Scan Barcode]
    B --> C{Product Found?}
    C -- Yes --> D[Add to List + Calc Total]
    C -- No --> E[Error: Product Not Available]
    D --> F[Select Payment Method]
    F --> G{Cash | Bank | Debt}
    G --> H[Store Invoice Locally]
    H --> I[Update Inventory - Decrease]
    I --> J[Finish & Print]
    
    K[Request Delete/Cancel Invoice] --> L[Set Invoice Status to CANCELED]
    L --> M[Send Stock Rejection Event - Return Quantities]
    M --> N[Log Action in Audit Trail]
    N --> O[Done]
```
