---
name: Spec Kit SDD
description: Structured methodology for Spec-Driven Development (SDD) in pharmaFix.
---

# Spec-Driven Development (SDD) with Antigravity

This skill governs the project through five distinct phases: **Constitution**, **Specification**, **Planning**, **Tasking**, and **Implementation**.

## The Phases

1.  **Constitution** (`/speckit.constitution`): Establish the non-negotiable architectural and quality standards.
2.  **Specification** (`/speckit.specify`): Define the *What* and *Why* of a feature.
3.  **Planning** (`/speckit.plan`): Define the *How* (tech stack & architecture).
4.  **Tasks** (`/speckit.tasks`): Break the plan into actionable, verifiable units.
5.  **Implementation** (`/speckit.implement`): Execute the tasks one by one.

## Governance Rules
*   Never start implementation without a task list.
*   Never create tasks without a plan.
*   Never plan without a specification.
*   Always respect the Constitution.
*   All artifacts go into `.specify/` unless otherwise noted.

## Integration with existing pharmaFix structure
*   **Constitution** maps to `_planning/ARCHITECTURE.md`.
*   **Roadmap** maps to `_planning/MASTER_PLAN.md`.
*   **Tasks** go into `_planning/tasks/TASK_XXX.md`.
