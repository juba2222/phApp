# Project Manager Skill: Atomic Development

This skill governs how **Antigravity** plans and executes tasks for PharmaFix. It ensures all changes are logical, atomic, and well-documented.

## Rules for Atomic Development
1.  **Micro-Tasks**: Never attempt multiple features at once. Break "Feature X" into "UI Prototype", "Data Model", "Logic", and "Integration".
2.  **Implementation Plans**: Before every new task, create an Implementation Plan artifact (`implementation_plan`) describing the "What, Why, and How".
3.  **Documentation First**: Update the `ROADMAP.md` or `BACKLOG.md` *before* starting a task and *after* completing it.
4.  **Verification**: After each task, run tests or verify the UI (using browser or terminal) before moving to the next.
5.  **Clean Architecture**: Ensure every task respects the layers defined in `ARCHITECTURE.md`.

## Standard Task Cycle
1.  **Select Task**: Choose the next highest priority from `ROADMAP.md`.
2.  **Plan**: Create/Update an Implementation Plan.
3.  **Build**: Execute code changes.
4.  **Verify**: Lint, test, or visual check.
5.  **Commit**: Mark as done in `ROADMAP.md`.
