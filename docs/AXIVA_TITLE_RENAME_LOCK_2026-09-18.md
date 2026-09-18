# AXIVA — Official Title Rename Decision

Status: **LOCKED DECISION / EFFECTIVE IMMEDIATELY**  
Date: 2026-09-18 JST  
Official title: **AXIVA**  
Reading: **アクシヴァ**  
Legacy title alias: **MACHI LOOP**

## Decision

The product formerly titled MACHI LOOP is officially renamed **AXIVA**.

MACHI LOOP is retained only as a migration/history alias for existing commits, save identifiers, URLs, paths, and other compatibility-sensitive references.

## Title-facing canonical rule

From this decision onward, title-facing canonical material uses **AXIVA**:

- GDD and product-facing specifications;
- Art Bible / Visual Canonical;
- README and current docs;
- gameplay title display;
- application/build display name;
- future images, handoffs, test records, and presentation material;
- workflow display labels where safe.

## Compatibility guardrail

The rename does **not** by itself authorize changing compatibility-sensitive internal identifiers.

Do not rename only for cosmetic consistency:

- save keys or save paths;
- schema identifiers;
- class names / script paths / internal constants;
- bundle identifiers;
- existing external URLs;
- CI identifiers or references whose migration could break current development;
- legacy asset filenames when the source file has not actually been renamed.

These may be migrated later only after impact review and with compatibility preserved.

## Repository rename

The GitHub repository currently remains `machi-loop` as a legacy technical identifier.

Repository rename is deferred until a safe checkpoint because it may affect GitHub Pages/external URLs and CI references. It is not required for the title decision to be effective.

## Product-state invariants

This title rename does not change:

- Core Loop;
- Product Direction;
- ACTIVE_PHASE;
- PRODUCTION_DECISION;
- RELEASE_APPROVAL;
- the current Vertical Slice / physical-iPhone validation NEXT.

## Canonical Art Bible

Current canonical path:

`docs/AXIVA_ART_BIBLE_V1.0.md`

Legacy compatibility alias:

`docs/MACHI_LOOP_ART_BIBLE_V1.0.md`
