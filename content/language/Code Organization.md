# Code Organization in Phaser

This document outlines the recommended code organization patterns for Phaser programs, emphasizing modularity, maintainability, and the separation of logical visibility from binary visibility.

## Design Philosophy

Phaser promotes clean code organization through several key principles:

- **Interface-First Design**: Define clear contracts before implementation
- **Compilation Units**: User-controlled boundaries for separate compilation
- **Logical vs Binary Visibility**: Separate symbol accessibility from linking concerns
- **Auto-Discovery**: Sensible defaults with explicit override capabilities
- **Local Reasoning**: Code should be understandable without distant context

## Project Structure

### Default Source Discovery

Phaser projects follow a convention-over-configuration approach:

```toml
# Phaser.toml - Minimal configuration
[package]
name = "my-project"
version = "0.1.0"
edition = "2024"

# By default, includes all sources under src/
# No need to specify sources unless you want to override
[compilation-units.main]
kind = "binary"
# sources = ["src/**/*.ph"]  # Implicit default

[compilation-units.lib]
kind = "library"
# sources = ["src/**/*.ph"]  # Implicit default
```

### Explicit Source Control (Optional)

When you need fine-grained control:

```toml
[compilation-units.core]
kind = "library"
sources = ["src/lib.ph", "src/math/**/*.ph", "src/utils/**/*.ph"]
dependencies = ["std"]

[compilation-units.cli]
kind = "binary"
sources = ["src/bin/main.ph", "src/cli/**/*.ph"]
dependencies = ["std", "core"]

[compilation-units.plugins]
kind = "wasm-module"
sources = ["src/plugins/**/*.ph"]
dependencies = ["std", "plugin-api"]
```

## Symbol Visibility

### Compilation Unit Scope + Parameterized Export

Using *scope keywords** with **parameterized export attributes**:

1. **Simple Logical Visibility**: Use `unit` keyword for compilation unit scope
2. **Flexible Binary Visibility**: Use `@export(...)` attributes with parameters
3. **Clear Separation**: Logical vs binary visibility are distinct concerns
4. **Rich Metadata**: Export attributes carry all necessary linking information

### Visibility Design

```phaser
// src/math/geometry.ph

// Default: file-local
struct InternalHelper {
    data: f64,
}

// unit: visible within compilation unit
unit struct Point {
    pub x: f64,
    pub y: f64,
}

// Binary export with static linking
@export(kind = "static", version = "1.0", abi = "c")
unit fn distance(p1: Point, p2: Point) -> f64 {
    let dx = p1.x - p2.x;
    let dy = p1.y - p2.y;
    (dx * dx + dy * dy).sqrt()
}

// Dynamic export for plugin system
@export(kind = "dynamic", version = "2.1", symbol = "create_geometry_plugin")
unit fn create_geometry_plugin() -> Box<dyn GeometryPlugin> {
    // Runtime plugin interface
}

// Export with custom name and compatibility
@export(kind = "static", name = "phaser_point_create", version = "1.0", 
        compat = ["0.9", "1.0"], deprecated = "2.0")
unit fn create_point(x: f64, y: f64) -> Point {
    Point { x, y }
}

// Conditional export based on features
@export(kind = "static", version = "1.0", 
        condition = "feature(advanced_math)")
unit fn advanced_calculation() -> f64 {
    // Only exported if advanced_math feature is enabled
}
```

### Export Attribute Parameters

The `@export` attribute supports these parameters:

#### Required Parameters

- **`kind`**: Export type
  - `"static"` - Static linking (default)
  - `"dynamic"` - Dynamic linking/plugins
  - `"wasm"` - WebAssembly export
  - `"c"` - C-compatible export

#### Optional Parameters

- **`version`**: Semantic version (e.g., `"1.2.3"`)
- **`name`**: Custom symbol name (overrides function/type name)
- **`symbol`**: Explicit symbol name for dynamic linking
- **`abi`**: Application Binary Interface
  - `"phaser"` - Native Phaser ABI (default)
  - `"c"` - C-compatible ABI
  - `"rust"` - Rust-compatible ABI
  - `"wasm"` - WebAssembly ABI
- **`compat`**: Compatible versions (array of version strings)
- **`deprecated`**: Version when symbol becomes deprecated
- **`condition`**: Conditional export (feature flags, target platform)
- **`doc`**: Documentation string for exported symbol
- **`stability`**: Stability level (`"stable"`, `"unstable"`, `"experimental"`)

### Visibility Rules

1. **Default (no keyword)**: File-local scope
2. **`Private`**: Explicitly private to the module. 
3. **`public`**: Accessible within the compilation unit (logical visibility)
4. **`@export(...)`**: Binary visibility with rich metadata
5. **Combined**: `@export(...)` + `public` for both logical and binary visibility

Notes on combining visbility: 
- **`public`**: Module public API callable  from other modules *within* this library  
- **`@export(...)`** + **`public`**: Public API also callable from outside the library. The export attribute defines wether the symbol is callable statically, dynamically, or both.  
It is possible to omit the `Public` for thhe edge case were the symbol must be dynamically loadable but not made part of the Public API.  

## Module System

### File-Based Modules

Each `.ph` file is automatically a module. No explicit module declarations needed:

```phaser
// src/math/geometry.ph
public struct Point {
    x: f64,
    y: f64,
}

@export public fn new() -> Point {
    Point { x: 0.0, y: 0.0 }
}

@export public fn distance(p1: Point, p2: Point) -> f64 {
    let dx = p1.x - p2.x;
    let dy = p1.y - p2.y;
    (dx * dx + dy * dy).sqrt()
}

// File-local helper (default visibility)
fn calculate_magnitude(x: f64, y: f64) -> f64 {
    (x * x + y * y).sqrt()
}

// inline modules can be defined, and can be named or annonymous
// TODO: think more carefully about implications of this idea
module {

}
```

### Import System

Import symbols from other modules using glob imports with selective overrides:

```phaser
// src/main.ph
import math.geometry;  // Import all exported symbols in module
import io.files.*; // Imports all sub-modules
import std.collections.*;

// Override specific imports if needed
import other.geometry.Point as OtherPoint;  // Rename to avoid conflicts
import utils.distance as util_distance;     // Rename conflicting function
import foobar.queue; // overrides the std.collections.* glob 

fn main() {
    let p1 = Point { x: 0.0, y: 0.0 };
    let p2 = Point { x: 3.0, y: 4.0 };
    let dist = distance(p1, p2);
    println("Distance: {}", dist);
  
    // Use renamed imports
    let other_p = OtherPoint::new();
    let util_dist = util_distance(p1, p2);
}
```

### Complete Example

```phaser
// src/graphics/renderer.ph

// File-local helper
struct RenderState {
    dirty: bool,
}

// Unit-visible type
unit struct Renderer {
    state: RenderState,
    pub width: u32,
    pub height: u32,
}

// Static export with C ABI for FFI
@export(kind = "static", abi = "c", version = "1.0", 
        name = "phaser_renderer_create")
unit fn create_renderer(width: u32, height: u32) -> *mut Renderer {
    // C-compatible constructor
}

// Dynamic export for plugin system
@export(kind = "dynamic", version = "1.0", 
        symbol = "renderer_plugin_interface",
        doc = "Main renderer plugin interface")
unit fn get_renderer_interface() -> Box<dyn RendererPlugin> {
    // Plugin interface
}

// WebAssembly export
@export(kind = "wasm", version = "1.0", name = "render_frame")
unit fn render_frame(renderer: &mut Renderer) -> i32 {
    // WASM-compatible render function
}

// Conditional export for debug builds
@export(kind = "static", version = "1.0", 
        condition = "cfg(debug_assertions)",
        stability = "unstable")
unit fn debug_render_stats(renderer: &Renderer) -> String {
    // Debug information
}
```

### Import Patterns

```phaser
// Glob import - brings in all exported symbols
import math.geometry.*;

// Specific import - only import what you need
import math.geometry.Point;

// Renamed import - avoid naming conflicts
import other.geometry.Point as OtherPoint;

// Namespace import - access via prefix
import math.geometry as geom;
// Use as: geom.Point, geom.distance()

// Conditional imports
#[cfg(feature = "advanced")]
import math.advanced.*;
```

### Separate Compilation

Each compilation unit can be built independently:

```bash
# Build only the core library
phaser build --unit core

# Build all units
phaser build

# Build with specific target
phaser build --unit plugins --target wasm32-wasi
```

## Interface Design Patterns

### Trait-Based Interfaces

Define behavior through traits:

```phaser
// src/io/traits.ph
pub trait Reader {
    type Error;
  
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Self::Error>;
    fn read_to_string(&mut self) -> Result<String, Self::Error>;
}

pub trait Writer {
    type Error;
  
    fn write(&mut self, buf: &[u8]) -> Result<usize, Self::Error>;
    fn write_all(&mut self, buf: &[u8]) -> Result<(), Self::Error>;
    fn flush(&mut self) -> Result<(), Self::Error>;
}
```

### Implementation Separation

Keep interface and implementation separate:

```phaser
// src/io/file_reader.ph
use super::traits::Reader;
use std::fs::File;
use std::io;

pub struct FileReader {
    file: File,
}

impl FileReader {
    pub fn open(path: &str) -> io::Result<Self> {
        let file = File::open(path)?;
        Ok(FileReader { file })
    }
}

impl Reader for FileReader {
    type Error = io::Error;
  
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Self::Error> {
        self.file.read(buf)
    }
  
    fn read_to_string(&mut self) -> Result<String, Self::Error> {
        let mut content = String::new();
        self.file.read_to_string(&mut content)?;
        Ok(content)
    }
}
```

## Capability-Based Design

### Capability Definitions

Define explicit capabilities for system access:

```phaser
// src/capabilities.ph
pub trait FileSystemCapability {
    fn read_file(&self, path: &str) -> Result<String, IoError>;
    fn write_file(&self, path: &str, content: &str) -> Result<(), IoError>;
    fn list_directory(&self, path: &str) -> Result<Vec<String>, IoError>;
}

pub trait NetworkCapability {
    fn http_get(&self, url: &str) -> Result<String, NetworkError>;
    fn http_post(&self, url: &str, body: &str) -> Result<String, NetworkError>;
}

pub struct Capabilities {
    filesystem: Option<Box<dyn FileSystemCapability>>,
    network: Option<Box<dyn NetworkCapability>>,
}
```

### Capability Injection

Pass capabilities explicitly to functions that need them:

```phaser
// src/services/config_loader.ph
use crate::capabilities::{Capabilities, FileSystemCapability};

pub struct ConfigLoader;

impl ConfigLoader {
    pub fn load_config(
        &self, 
        caps: &Capabilities, 
        path: &str
    ) -> Result<Config, ConfigError> {
        let fs = caps.filesystem()
            .ok_or(ConfigError::NoFileSystemAccess)?;
    
        let content = fs.read_file(path)
            .map_err(ConfigError::IoError)?;
    
        self.parse_config(&content)
    }
  
    fn parse_config(&self, content: &str) -> Result<Config, ConfigError> {
        // Parse configuration from string
        todo!()
    }
}
```

## Error Handling Patterns

### Result-Based Error Handling

Use `Result<T, E>` for recoverable errors:

```phaser
// src/math/calculator.ph
#[derive(Debug)]
pub enum MathError {
    DivisionByZero,
    InvalidInput(String),
    Overflow,
}

pub struct Calculator;

impl Calculator {
    pub fn divide(a: f64, b: f64) -> Result<f64, MathError> {
        if b == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            Ok(a / b)
        }
    }
  
    pub fn sqrt(x: f64) -> Result<f64, MathError> {
        if x < 0.0 {
            Err(MathError::InvalidInput("Cannot take square root of negative number".to_string()))
        } else {
            Ok(x.sqrt())
        }
    }
}
```

### Error Propagation

Use the `?` operator for clean error propagation:

```phaser
// src/math/complex_operations.ph
use super::calculator::{Calculator, MathError};

pub fn quadratic_formula(a: f64, b: f64, c: f64) -> Result<(f64, f64), MathError> {
    let discriminant = b * b - 4.0 * a * c;
    let sqrt_discriminant = Calculator::sqrt(discriminant)?;
  
    let denominator = 2.0 * a;
    let x1 = Calculator::divide(-b + sqrt_discriminant, denominator)?;
    let x2 = Calculator::divide(-b - sqrt_discriminant, denominator)?;
  
    Ok((x1, x2))
}
```

## Testing Organization

### Unit Tests

Place unit tests alongside the code they test:

```phaser
// src/math/geometry.ph
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn distance_to(&self, other: &Point) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx * dx + dy * dy).sqrt()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
  
    #[test]
    fn test_distance_calculation() {
        let p1 = Point { x: 0.0, y: 0.0 };
        let p2 = Point { x: 3.0, y: 4.0 };
    
        assert_eq!(p1.distance_to(&p2), 5.0);
    }
  
    #[test]
    fn test_distance_symmetry() {
        let p1 = Point { x: 1.0, y: 2.0 };
        let p2 = Point { x: 4.0, y: 6.0 };
    
        assert_eq!(p1.distance_to(&p2), p2.distance_to(&p1));
    }
}
```

### Integration Tests

Place integration tests in a separate directory:

```
tests/
├── integration/
│   ├── math_operations.ph
│   ├── file_processing.ph
│   └── network_client.ph
└── fixtures/
    ├── sample_data.json
    └── test_config.toml
```

```phaser
// tests/integration/math_operations.ph
use my_project::math::{Calculator, Point};

#[test]
fn test_complex_calculation() {
    let result = Calculator::divide(10.0, 2.0).unwrap();
    assert_eq!(result, 5.0);
  
    let sqrt_result = Calculator::sqrt(result).unwrap();
    assert!((sqrt_result - 2.236).abs() < 0.001);
}

#[test]
fn test_geometry_integration() {
    let origin = Point { x: 0.0, y: 0.0 };
    let point = Point { x: 3.0, y: 4.0 };
  
    let distance = origin.distance_to(&point);
    assert_eq!(distance, 5.0);
}
```

## Documentation Patterns

### Module Documentation

Document modules with clear purpose and usage examples:

```phaser
//! # Geometry Module
//! 
//! This module provides geometric types and operations for 2D and 3D space.
//! 
//! ## Examples
//! 
//! ```phaser
//! use geometry::{Point, Line};
//! 
//! let p1 = Point::new(0.0, 0.0);
//! let p2 = Point::new(3.0, 4.0);
//! let distance = p1.distance_to(&p2);
//! assert_eq!(distance, 5.0);
//! ```

pub struct Point {
    /// X coordinate
    pub x: f64,
    /// Y coordinate  
    pub y: f64,
}
```

### API Documentation

Document public APIs with examples and edge cases:

```phaser
impl Calculator {
    /// Divides two numbers, returning an error if the divisor is zero.
    /// 
    /// # Arguments
    /// 
    /// * `a` - The dividend
    /// * `b` - The divisor
    /// 
    /// # Returns
    /// 
    /// Returns `Ok(result)` if successful, or `Err(MathError::DivisionByZero)` 
    /// if `b` is zero.
    /// 
    /// # Examples
    /// 
    /// ```phaser
    /// let result = Calculator::divide(10.0, 2.0)?;
    /// assert_eq!(result, 5.0);
    /// 
    /// let error = Calculator::divide(10.0, 0.0);
    /// assert!(error.is_err());
    /// ```
    pub fn divide(a: f64, b: f64) -> Result<f64, MathError> {
        if b == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            Ok(a / b)
        }
    }
}
```

This organization promotes maintainable, testable, and well-documented Phaser code that scales from small scripts to large systems while maintaining clarity and performance.
