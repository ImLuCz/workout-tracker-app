---
description: Apply project conventions — read AGENTS.md, delegate to sub-agents, keep docs in sync
argument-hint: "[instructions]"
---

Before doing any work on this project, follow these steps in order:

## 1. Read the Project Guide

Read `AGENTS.md` fully. This file documents the project's architecture, conventions, and layer responsibilities. All subsequent work must conform to what is described there.

## 2. Use Sub-Agents Whenever Possible

Do **not** perform multi-step or independent tasks yourself. Instead, delegate them to sub-agents using the `Agent` tool:

- **Parallelizable work** → launch multiple sub-agents at once (e.g., adding two screens, writing two models).
- **Independent concerns** → each gets its own sub-agent (e.g., one for UI, one for data layer).
- **Large or ambiguous tasks** → use a sub-agent with a clear brief so it can reason independently.

Only orchestrate sub agents, do not perform changes yourself.

## 3. Update AGENTS.md When Documented Items Change

After completing any work, review `AGENTS.md` and update it **if** your changes affect anything it documents, including but not limited to:

- New files or directories added to `lib/`
- New or modified architecture layers
- New or changed dependencies
- New or changed conventions (naming, patterns, state management, routing)
- New screens, view models, repositories, or models
- Changes to the route table in `navigation/router.dart`
- Changes to `main.dart` provider setup

If no documented item changed, skip this step.

## 4. Proceed with the Task

Now follow the user's instructions, respecting the conventions from `AGENTS.md` and using sub-agents where appropriate.
