# PharmaFix: Search & Filtering Requirements

To make the search feature "best-in-class," we need to plan the following logic.

## 1. Search Logic (Debounced)
- Don't search while typing every character.
- Trigger search after **300ms** of inactivity.
- Support bilingual search (User types "Panadol" or "بنادول").

## 2. Filtering Criteria
- **Category**: Filter by medical class.
- **Price Range**: Slider for min/max price.
- **Prescription Status**: "Only show OTC (Over-the-counter) meds".
- **Availability**: "Only show available in nearest pharmacy".

## 3. UI Requirements
- **Search History**: Save recent searches locally (Hive).
- **Suggestions**: Show "Top searched" while typing.
- **Micro-interactions**: Subtle pulse icon when searching.
- **Empty States**: Friendly "No medicine found" illustrations.
