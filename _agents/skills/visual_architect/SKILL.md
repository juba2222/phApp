---
name: Visual Architect (Mermaid.js)
description: Skill for creating and interpreting Mermaid.js diagrams (Flowcharts, ERD, Sequence, etc.) to guide development.
---

# Visual Architect Skill

This skill allows **Antigravity** to act as a system architect using **Mermaid.js**. It ensures all complex logic and data structures are visualized before implementation.

## Diagram Types & Usage
1.  **Flowcharts** (`graph TD`): Use for complex business logic, search algorithms, and user flows.
2.  **Entity Relationship Diagrams** (`erDiagram`): Use for database schema, state management models, and data types.
3.  **Sequence Diagrams** (`sequenceDiagram`): Use for API interactions, authentication flows, and cross-service communication.
4.  **State Diagrams** (`stateDiagram-v2`): Use for UI state management (e.g., Bloc states, loading/error/success).

## Rules for Diagrams
- **Location**: All diagrams must be saved in `_planning/visuals/` as `.md` files containing Mermaid code blocks.
- **Precision**: Labels must be clear and descriptive.
- **Synchronization**: If the code logic changes, the diagram MUST be updated first.
- **Reference**: Every `implementation_plan` should reference at least one diagram from `_planning/visuals/`.

## Standard Lifecycle
1.  **Sketch**: Create a draft Mermaid code block in the chat.
2.  **Save**: Write the final Mermaid diagram to `_planning/visuals/{feature}_diagram.md`.
3.  **Implement**: Use the visual map as the absolute source of truth for writing logic.
