//! Render layer - flat API for all render effects
//!
//! Provides instant rendering and animations.
//! Implementation details are in render/ subdirectory.

const Block = @import("block.zig").Block;

// Re-export render effects with flat API
const instant_impl = @import("render/instant.zig");
const fade_in_impl = @import("render/fade_in.zig");

/// Instant render - output Block immediately
pub const instant = instant_impl.instant;

/// Fade-in animation - progressive reveal with alpha blending
pub const fadeIn = fade_in_impl.fadeIn;

/// Fade-in configuration
pub const FadeInConfig = fade_in_impl.Config;

/// Staggered fade-in animation - lines fade in from top to bottom
pub const staggeredFadeIn = fade_in_impl.staggeredFadeIn;
pub const StaggeredFadeInConfig = fade_in_impl.StaggeredConfig;

// Legacy compatibility (deprecated)
pub const render = instant;
pub const FadeConfig = FadeInConfig;
