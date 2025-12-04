# Implementation Guide

## Development Environment

### Language Configuration
- **Language**: Zig (master branch)
- **Build System**: Zig build system (build.zig)
- **Project Structure**: Single library module with submodules
- **Documentation**: Follow https://ziglang.org/documentation/master/

### Build Environment
- **Nix flake**: Reproducible development environment with Zig toolchain
- **Required**: Zig compiler (master/nightly or v0.16 candidate)
- **Development shell**: `nix develop` or `direnv allow`

### Dependency Management
- **Zero external dependencies**: Only Zig standard library
- **No package manager needed**: Self-contained library
- **build.zig.zon**: Package manifest for library consumers
- **Vendoring**: Library can be easily vendored into projects

## Coding Standards

### Code Style

#### Zig Idioms
- Follow Zig naming conventions: camelCase for functions, PascalCase for types
- Use `snake_case` for local variables and parameters
- Explicit is better than implicit - no hidden control flow
- Prefer comptime for compile-time known values

#### Memory Management
- All allocations must go through `std.mem.Allocator` parameter
- Document which functions allocate and how memory should be freed
- Use `defer` for cleanup in error paths
- Consider using arena allocators for batch operations

#### Error Handling
- Use error unions (`!T`) for fallible operations
- Provide specific error sets, not `anyerror`
- Use `try` for propagation, `catch` for recovery
- Use `errdefer` for cleanup on error paths

#### Code Organization
- Keep public API surface minimal and well-documented
- Group related functions and types in same file
- Use `pub` judiciously - default to private
- Export library API through root.zig

### Type Safety

- Leverage Zig's type system for safety
- Use optionals (`?T`) for nullable values
- Avoid undefined behavior - initialize all variables
- Use sentinel-terminated slices when appropriate
- Prefer compile-time type checking over runtime checks

### Documentation Standards

- Document all public functions with doc comments (`///`)
- Include parameter descriptions and return value behavior
- Provide usage examples for non-trivial functions
- Document error conditions and allocation behavior
- Reference relevant Zig stdlib patterns

## Development Practices

### Testing Strategy

#### Built-in Testing Framework
- Use Zig's built-in `test` blocks for unit tests
- Test both success and error paths
- Use `std.testing.allocator` to detect memory leaks
- Place tests close to the code they test

#### Testing Commands
```bash
# Run all tests
zig build test

# Run tests with specific filter
zig build test -- [filter]

# Run tests in debug mode
zig build test -Doptimize=Debug
```

#### Test Requirements
- All public functions must have tests
- Test error conditions and edge cases
- Verify no memory leaks with testing allocator
- Use descriptive test names
- Include doc tests for examples

### Performance Guidelines

#### Optimization Strategy
- Profile first, optimize second - measure before changing
- Use comptime for zero-cost abstractions
- Prefer stack allocation when size is known
- Use arena allocators for temporary allocations
- Minimize allocations in hot paths

#### Buffer Management
- Reuse buffers when possible
- Pre-calculate required sizes to avoid reallocation
- Consider providing buffer-based APIs alongside allocating APIs
- Document buffer size requirements

### Build Configuration

#### build.zig Structure
- Define library as module export
- Include test step with all tests
- Provide examples as separate executables
- Keep build script simple and maintainable