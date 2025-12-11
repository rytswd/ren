# Project Overview

## Description
`Ren` (練) is a lightweight Zig library for sophisticated terminal output rendering. The name comes from 洗練 (senren), meaning "refined" or "sophisticated" - reflecting the project's core philosophy: simple, small, and sophisticated.

It provides utilities for creating refined terminal interfaces with features like box drawing, styled text rendering, and flexible layout management - all while maintaining simplicity and zero external dependencies.

The project follows documentation-driven development methodology, where planning documents serve as the single source of truth for project requirements and specifications.

## Core Principles
- **Simple**: Keep the API intuitive and straightforward for common use cases
- **Small**: Zero dependencies, minimal code footprint, only Zig stdlib
- **Sophisticated**: Refined output with attention to Unicode, alignment, and visual polish
- **Performance**: Leverage Zig's compile-time optimizations for efficient rendering
- **Composability**: Building blocks that work well together

## Technology Stack
- **Language**: Zig (following master branch documentation)
- **Standard Library**: Zig stdlib for all operations
- **Build System**: Zig build system (build.zig)
- **Documentation**: Follows https://ziglang.org/documentation/master/
- **Testing**: Zig's built-in testing framework

## Project Structure
```
ren/
├── src/              # Zig source code
│   ├── root.zig      # Library root/main entry point
│   ├── box.zig       # Box drawing utilities
│   ├── zen.zig       # Zen printer implementation
│   └── ...           # Other modules
├── build.zig         # Zig build configuration
├── build.zig.zon     # Zig package manifest
├── air/              # Air documentation
│   ├── v0.1/         # Version 0.1 specifications
│   ├── context/      # Generated context files
│   └── templates/    # Document templates
├── flake.nix         # Nix development environment
└── devshell.nix      # Nix shell configuration
```

## Architecture
`Ren` is designed as a library of composable printing utilities. Each module provides focused functionality that can be used independently or combined for more complex output rendering.

Key design decisions:
- **Compile-time configuration**: Use Zig's comptime features for zero-cost abstractions
- **Allocator-aware**: Explicit memory management through std.mem.Allocator
- **UTF-8 support**: Proper handling of Unicode characters in terminal output
- **No global state**: All functions are pure or explicitly manage state

## Core Components

### Box Printer
The box printer module provides utilities for drawing boxes around text content with customizable borders, padding, and alignment. Supports various box-drawing character sets (ASCII, Unicode box-drawing characters).

### Zen Printer
A minimalist printing utility focused on clean, distraction-free output formatting. Provides simple APIs for common terminal output patterns.

## Document States (Air Workflow)
Air uses these predefined states to track document lifecycle:
- `draft` - Initial planning phase
- `ready` - Specification complete, ready for implementation
- `work-in-progress` - Currently being implemented
- `complete` - Implementation finished
- `dropped` - No longer needed
- `unknown` - State cannot be determined

## Getting Started
<!-- TODO: Customize for your project -->
1. Review current status: `airctl status`
2. Check ready work: `airctl status --state ready`
3. Read relevant Air documents in `./air/` before implementing
4. Update document states as work progresses

## Current Focus
Use `airctl status --state work-in-progress,ready` to see current priorities and available work.