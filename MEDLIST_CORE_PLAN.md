# MedList App - Core Function Plan (Build-Ready)

## User Requirements (Priority)

### 1. Core Data Fields (Stock/Inventory View)
| Field | Model | Status |
|-------|-------|--------|
| Brand ng gamot | Medication.tradeName | Done |
| Supplier ng gamot | Medication.company (manufacturer) + supplier field | Add supplier |
| Expiry | StockItem.expiryDate | Done |
| Batch production | StockItem.batchNumber, manufacturingDate | Done (need DB migration) |
| Generic name | Medication.activeIngredient | Done |
| Quantity | StockItem.quantity | Done |

### 2. Reports & Export
| Feature | Status |
|---------|--------|
| Export to Excel | Done |
| Export to Word (DOCX) | To implement |
| Report sent via email | Share supports email - enhance with mailto option |

### 3. QR Code
| Feature | Status |
|---------|--------|
| QR code scanner | Done (mobile_scanner supports QR) |
| QR code reader | Same scanner reads QR |

---

## Implementation Checklist

### Phase 1: Data & DB (Core) - DONE
- [x] Medication: tradeName (brand), activeIngredient (generic), company, supplier
- [x] StockItem: quantity, expiryDate, batchNumber, manufacturingDate
- [x] DB migration v3: storage_condition, is_controlled_drug, therapeutic_category, supplier to medications
- [x] DB migration v3: manufacturing_date, expected_quantity to stock_items

### Phase 2: Stock/Report Display - DONE
- [x] Stock report: Brand, Supplier, Expiry, Batch, Generic, Quantity
- [x] Export reports with all core fields (CSV, PDF, Excel, Word)
- [x] Word (.doc) export (HTML-based, opens in Word)

### Phase 3: Share & Email - DONE
- [x] Share.shareXFiles (opens share sheet - includes Email, Gmail, etc.)
- [x] Reports can be sent via email from share options

### Phase 4: QR/Barcode - DONE
- [x] Barcode scanner (mobile_scanner - supports both barcode and QR)
- [x] QR code scanner/reader (same scanner)

### Phase 5: Existing Gaps (From Requirements)
- [ ] User roles (Pharmacist, Doctor, etc.)
- [ ] PIN/biometric login
- [ ] Patient profile
- [ ] MIMS structured display
- [ ] Push notifications

---

## Data Mapping

**Medication (Brand/Generic/Supplier):**
- tradeName = Brand
- activeIngredient = Generic name
- company = Manufacturer/Supplier

**StockItem (Batch/Expiry/Qty):**
- batchNumber = Batch production
- manufacturingDate = Batch production date
- expiryDate = Expiry
- quantity = Quantity
