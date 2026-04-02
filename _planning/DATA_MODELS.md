# PharmaFix: Data Models & Schemas

This document defines the core entities used across the application. These will be implemented as `freezed` models in the Data Layer.

## 1. Medicine Entity (MedicineModel)
The central object of the app.
- `id`: `String` (UUID)
- `nameEn`: `String` (e.g., "Panadol Advance")
- `nameAr`: `String` (e.g., "بنادول أدفانس")
- `description`: `String` (Instruction, Side effects)
- `category`: `Enum` (Analgesic, Antibiotic, etc.)
- `dosage`: `String` (500mg)
- `price`: `double`
- `requiresPrescription`: `bool`
- `imageUrl`: `String`
- `activeIngredients`: `List<String>`

## 2. Pharmacy Entity (PharmacyModel)
- `id`: `String`
- `name`: `String`
- `location`: `GeoPoint` (lat, lng)
- `address`: `String`
- `phoneNumber`: `String`
- `isOpen`: `bool`
- `stockStatus`: `Map<String, int>` (MedicineId -> Quantity)
- `rating`: `double`

## 3. User Entity (UserModel)
- `id`: `String`
- `email`: `String`
- `fullName`: `String`
- `role`: `Enum` (Customer, Pharmacist, Admin)
- `favouriteMedicines`: `List<String>` (MedicineIds)
- `prescriptionHistory`: `List<String>` (PrescriptionIds)

## 4. Prescription Entity (PrescriptionModel)
- `id`: `String`
- `userId`: `String`
- `imageUrl`: `String`
- `status`: `Enum` (Pending, Verified, Rejected, Fulfilled)
- `uploadedAt`: `DateTime`
- `verifiedBy`: `String` (PharmacistId)
