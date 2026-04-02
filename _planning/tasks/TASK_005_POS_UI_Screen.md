# Task List: POS Sales Interface (TASK_005)

> **Reference Plans**: PLAN_001, PLAN_002
> **Reference Specs**: SPEC_001, SPEC_003
> **Constitution Rules**: Speed ≤ 300ms, Selling flow ≤ 3 steps.

---

## 1. POS Screen Layout (Atomic Design)

### Atoms (Base Elements)
- [ ] `BarcodeInputField`: Focused, auto-clear after scan.
- [ ] `QuantityBadge`: Shows current qty in cart with +/- controls.
- [ ] `PriceTag`: Formatted currency display (Decimal precision).

### Molecules (Groups)
- [ ] `CartItemTile`: Product name + Expiry date chip + price + remove button.
- [ ] `PaymentChooser`: Segmented control for CASH | BANK | DEBT.

### Organisms (Complex Sections)
- [ ] `CartList`: Scrollable list of `CartItemTile` widgets.
- [ ] `InvoiceSummaryBar`: Subtotal, discount, and total display.

---

## 2. State Integration (SalesCubit → UI)
- [ ] Connect `BarcodeInputField` to `SalesCubit.scanProduct()` event.
- [ ] Show loading indicator while `SalesScanning` state is active.
- [ ] Show `ExpiryWarningSnackbar` if item expires within 30 days.
- [ ] Handle `SalesError` state with a prominent error dialog + rollback message.

---

## 3. Payment Flow (≤ 3 Steps as per Constitution §7.1)

### Step 1: Scan → Item appears instantly in cart.
### Step 2: Choose Payment Type (Cash/Bank/Debt).
### Step 3: Tap "Confirm" → Invoice saved → Screen clears.

- [ ] If DEBT: Show `CustomerSearchDialog` (required field per SPEC_001).
- [ ] "Confirm" button disabled until payment type is selected.
- [ ] Show "Confirm" countdown animation when `SalesCommitting` state is active.

---

## 4. Cancellation Dialog
- [ ] Implement `CancelInvoiceDialog` (requires Admin PIN or confirmation).
- [ ] Upon confirmation, dispatch `CancelInvoice` event to Cubit.

---

## 5. Polish & Performance
- [ ] Add smooth item entry animation (slide-in from right).
- [ ] Add total amount counter animation (smooth number roll-up).
- [ ] Ensure the scan field auto-focuses on screen open.

---

## 6. Verification
- [ ] Integration Test: Simulate scanning 3 items across 2 batches and verify total.
- [ ] Performance Test: Scan → Add latency must be < 300ms.
