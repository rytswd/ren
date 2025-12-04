# System Architecture

## Core Philosophy

`ren` (練) embodies the principle of 洗練 (senren) - sophistication through refinement. It's a lightweight Zig library for terminal output that achieves sophisticated results through simple, small, and composable building blocks.

**Simple, Small, Sophisticated:**
- **Simple**: Intuitive APIs that make common tasks easy
- **Small**: Zero external dependencies, minimal code footprint
- **Sophisticated**: Refined output with proper Unicode handling, alignment, and visual polish

The project follows documentation-driven development principles, where planning documents serve as the single source of truth for project requirements and specifications.

## Design Principles

### Zig-First Design
- Follow Zig's philosophy: no hidden control flow, no hidden memory allocations
- Leverage compile-time evaluation (comptime) for zero-cost abstractions
- Explicit error handling using Zig's error unions
- Clear ownership and lifetime management

### Allocator Awareness
- All allocations go through explicit `std.mem.Allocator` parameters
- Users control memory allocation strategy (GPA, arena, fixed buffer, etc.)
- No global state or hidden allocations
- Clear documentation of allocation behavior

### Simplicity and Composability
- Small, focused modules that do one thing well
- Pure functions where possible
- Easy to combine utilities for complex layouts
- Minimal API surface for common use cases

### Zero Dependencies
- Rely only on Zig standard library
- No external C dependencies
- Cross-platform support through Zig's stdlib abstractions
- Self-contained and easy to vendor

## System Architecture

```
ren/
├── src/
│   ├── root.zig           # Library entry point, public API exports
│   ├── box.zig            # Box drawing module
│   ├── zen.zig            # Zen printer module
│   ├── types.zig          # Common types and enums
│   ├── unicode.zig        # Unicode handling utilities
│   └── writer.zig         # Writer abstraction and utilities
├── build.zig              # Zig build script
└── build.zig.zon          # Package manifest
```

### Module Architecture

#### root.zig (Library Entry Point)
- Public API surface - exports all user-facing functionality
- Re-exports types and functions from submodules
- Contains library-wide configuration and constants
- Minimal logic, mostly organizational

#### box.zig (Box Drawing)
- Box drawing character sets (ASCII, Unicode box-drawing)
- Border styles and configurations
- Padding and alignment options
- Main rendering logic for boxed content

#### zen.zig (Zen Printer)
- Minimalist output formatting
- Simple text alignment and spacing
- Clean API for common patterns

#### types.zig (Common Types)
- Shared enums (BorderStyle, Alignment, etc.)
- Configuration structs
- Common type aliases

## Core Components

### 1. Box Printer System

The box printer is the primary feature of `ren`, providing flexible box drawing around text content.

#### Key Features
- Multiple border styles (single, double, rounded, ASCII-only)
- Configurable padding (top, bottom, left, right)
- Text alignment (left, center, right)
- Multi-line content support
- UTF-8 aware width calculations

#### Design Approach
- Allocator parameter for memory management
- Writer-based output (compatible with `std.Io.Writer`)
- Comptime configuration for zero-cost abstractions
- Efficient buffer management for rendering

### 2. Zen Printer System

Minimalist printing utilities for clean terminal output.

#### Key Features
- Simple text formatting and alignment
- Minimal API surface
- Composable with other ren utilities
- Focus on readability and ease of use

### 3. Unicode Support

Proper handling of Unicode characters is essential for terminal rendering.

#### Implementation Approach
- UTF-8 validation and iteration using `std.unicode`
- Width calculation respecting Unicode grapheme clusters
- Support for box-drawing characters (U+2500 - U+257F)
- East Asian Width handling for proper alignment

### 4. Writer Abstraction

Writer pattern for output flexibility.

#### Design
- Built on `std.Io.Writer` interface (non-generic, buffered)
- Users provide buffer for Writer instances
- Error handling through Zig error unions
- Compatible with stdout, files, or custom writers via vtable

## Technology Stack

### Language and Runtime
- **Language**: Zig (master branch)
- **Documentation**: https://ziglang.org/documentation/master/
- **Standard Library**: https://ziglang.org/documentation/master/std/
- **Key Features Used**:
  - Comptime evaluation for zero-cost abstractions
  - Error unions for explicit error handling
  - Explicit allocators for memory management
  - Generic types for reusable components

### Dependencies
- **Zero external dependencies**: Only Zig standard library
- **Standard Library Modules**:
  - `std.mem`: Memory management and Allocator type
  - `std.Io`: I/O interface with Writer and Reader
  - `std.unicode`: UTF-8 validation and iteration
  - `std.testing`: Built-in testing framework
  - `std.fmt`: Formatting utilities

### Build System
- **Build Tool**: Zig build system (build.zig)
- **Package Management**: build.zig.zon for package manifest
- **Testing**: `zig build test`
- **Development**: Nix flake for reproducible dev environment

## Performance Considerations

<!-- TODO: Add your project's specific performance considerations -->

### File System Operations
- Use `ignore` crate for efficient directory traversal
- Respect .gitignore patterns to avoid scanning unnecessary files
- Parallel processing for large document sets
- Incremental scanning for changed files only

### Memory Management
- Stream processing for large files where possible
- Lazy loading of document content
- Efficient string handling with Rust's ownership system
- Metadata cache (future) to reduce repeated parsing

### Git Operations
- Cache git repository handles
- Batch git operations when possible
- Fallback strategies when git operations fail
- Optional git integration - never required for core functionality

## Error Handling Strategy

<!-- TODO: Describe your project's error handling approach -->

### Error Types
- **Configuration Errors**: Invalid TOML, missing files, permission issues
- **Document Errors**: Invalid metadata, unsupported formats
- **Git Errors**: Repository access, permission issues
- **IO Errors**: File system access, network issues

### Error Reporting
- Use `thiserror` for structured error handling
- Chain errors with `?` operator for clean code flow
- Provide actionable error messages with suggestions
- Graceful degradation when optional features fail

### Recovery Strategies
- Fallback to defaults for missing configuration
- Continue processing when individual documents fail
- Provide partial results with warnings
- Clear indication of what failed and why

## Future Architecture Considerations

<!-- TODO: Describe planned architectural improvements and extensions -->

### Scalability
- Metadata cache with SQLite for large document sets
- Incremental updates instead of full rescans
- Streaming APIs for very large projects
- Background processing for expensive operations

### Extensibility
- Plugin system for custom document formats
- Hook system for external tool integration
- Custom state definitions (post-v0.1)
- API endpoints for web interface integration

### Multi-User Support
- Shared configuration management
- Conflict resolution for concurrent edits
- User-specific views and preferences
- Audit logging for document changes