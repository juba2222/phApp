# SPEC.md — Project Specification

> **Status**: `FINALIZED`

## Vision
PharmaFix is a premium Flutter application designed to bridge the gap between pharmacies and patients through seamless medicine discovery, real-time stock tracking, and professional pharmacy services.

## Goals
1. **Medicine Discovery**: Advanced dual-language search (Arabic/English) with dosage and price filtering.
2. **Real-time Inventory**: Reliable stock tracking and management for pharmacy owners.
3. **Professional Services**: Prescription scanning/uploading and GPS-based pharmacy location services.
4. **Premium UX**: High-end aesthetics (Glassmorphism), 60fps animations, and minimalist design.

## Non-Goals (Out of Scope)
- Direct e-commerce/payment processing (v1.0).
- Social networking between users.
- Medical diagnosis or tele-health advice.

## Users
- **Customers**: Search for medications, find nearby pharmacies, and upload prescriptions.
- **Pharmacists**: Manage inventory, confirm availability, and process prescriptions.

## Constraints
- **Platform**: Flutter (Core framework).
- **Environment**: Strict linting and clean architecture.
- **Accessibility**: Support for both Arabic (RTL) and English (LTR) layouts.
- **Performance**: Fast load times and offline-first capabilities.

## Success Criteria
- [ ] Functional Flutter skeleton with professional directory structure.
- [ ] Working search engine with < 200ms latency on local data.
- [ ] Successful prescription upload and image preview.
- [ ] GPS-based map with pharmacy markers.
