# Raycast Reference

## What Raycast Is

Raycast is a keyboard-first launcher and productivity layer. It acts as a command palette for the operating system, letting the user search for actions, run commands, manage clipboard history, trigger workflows, and use extensions from one consistent interface.

## Core Product Traits

- Fast, global invocation from the keyboard
- Search-first UI with fuzzy matching
- Commands as the main abstraction
- Rich metadata for each command: title, subtitle, icon, alias, category
- Extensions/plugins instead of one giant built-in script
- Consistent execution model across many actions
- Strong focus on low friction and immediate feedback

## Why It Feels Powerful

Raycast reduces context switching. Instead of opening many apps or remembering many hotkeys, the user opens one launcher, types intent, and executes an action immediately.

It also scales well because new capabilities fit the same mental model:

- Open launcher
- Type what you want
- Confirm action

## Functional Areas Raycast Typically Covers

- App launching
- File and folder navigation
- Clipboard history
- Snippets/templates
- Window management
- Calculations and conversions
- Calendar and reminders
- AI text transformations
- Developer commands
- Extension-based integrations with other tools

## Interaction Model

The user usually starts from one of these inputs:

- No input, just an intent
- Selected text
- Clipboard contents
- Current app/window context
- Typed arguments

The system then routes that input into a command and returns either:

- An immediate side effect
- A preview
- A copied result
- A pasted replacement
- A follow-up action

## Architectural Pattern Behind It

A Raycast-like system is usually built around:

- A launcher UI
- A command registry
- A context collector
- A plugin or extension model
- Shared services for clipboard, windows, search, config, and history

This matters because the product is not "one useful script." It is a platform that makes many small actions feel uniform.

## What Makes It Hard To Copy

The difficulty is not just the menu UI. The hard parts are:

- Excellent responsiveness
- Strong command discovery
- Consistent UX across commands
- Reliable system integrations
- A clean extension model
- Good defaults, ranking, and history

## Implication For This Project

If this project wants to become "more like Raycast," it should evolve from a single workflow script into a local command platform for text and desktop actions.
