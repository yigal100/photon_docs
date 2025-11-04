# Phaser Language Examples

This document provides comprehensive examples of Phaser language syntax and features, demonstrating the practical application of the [[Grammar Specification]] and [[Design Principles]].

## Basic Syntax

### Hello World

```phaser
fn main() -> i32 {
    println!("Hello, Phaser!");
    return 0;
}
```

### Variables and Types

```phaser
fn variables_example() {
    // Immutable by default
    let x = 42;
    let name = "Phaser";
    
    // Explicit mutability
    let mut counter = 0;
    counter += 1;
    
    // Type annotations
    let age: u32 = 25;
    let pi: f64 = 3.14159;
    let is_active: bool = true;
    
    // Type inference
    let numbers = [1, 2, 3, 4, 5]; // [i32; 5]
    let message = "Hello".to_string(); // String
}
```

### Functions

```phaser
// Basic function
fn add(a: i32, b: i32) -> i32 {
    a + b // Expression-based return
}

// Function with explicit return
fn multiply(x: i32, y: i32) -> i32 {
    return x * y;
}

// Generic function
fn max<T>(a: T, b: T) -> T 
where 
    T: PartialOrd + Copy 
{
    if a > b { a } else { b }
}

// Function with multiple return values (tuple)
fn divide_with_remainder(dividend: i32, divisor: i32) -> (i32, i32) {
    (dividend / divisor, dividend % divisor)
}
```

## Data Structures

### Structs

```phaser
// Named struct
struct Point {
    x: f64,
    y: f64,
}

// Tuple struct
struct Color(u8, u8, u8);

// Unit struct
struct Marker;

// Generic struct
struct Container<T> {
    value: T,
    count: usize,
}

// Struct with methods
impl Point {
    fn new(x: f64, y: f64) -> Self {
        Point { x, y }
    }
    
    fn distance_from_origin(&self) -> f64 {
        (self.x * self.x + self.y * self.y).sqrt()
    }
    
    fn translate(&mut self, dx: f64, dy: f64) {
        self.x += dx;
        self.y += dy;
    }
}
```

### Enums

```phaser
// Simple enum
enum Direction {
    North,
    South,
    East,
    West,
}

// Enum with data
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(u8, u8, u8),
}

// Generic enum
enum Option<T> {
    Some(T),
    None,
}

enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

## Control Flow

### Conditionals

```phaser
fn conditional_examples(x: i32) -> String {
    // Basic if-else
    if x > 0 {
        "positive"
    } else if x < 0 {
        "negative"
    } else {
        "zero"
    }.to_string()
    
    // If as expression
    let abs_x = if x >= 0 { x } else { -x };
    
    format!("Value: {}, Absolute: {}", x, abs_x)
}
```

### Pattern Matching

```phaser
fn pattern_matching_examples() {
    let message = Message::Move { x: 10, y: 20 };
    
    match message {
        Message::Quit => println!("Quit message"),
        Message::Move { x, y } => println!("Move to ({}, {})", x, y),
        Message::Write(text) => println!("Text: {}", text),
        Message::ChangeColor(r, g, b) => println!("Color: ({}, {}, {})", r, g, b),
    }
    
    // Match with guards
    let number = 42;
    match number {
        n if n < 0 => println!("Negative: {}", n),
        0 => println!("Zero"),
        1..=10 => println!("Small positive"),
        _ => println!("Large positive"),
    }
    
    // Destructuring
    let point = Point { x: 1.0, y: 2.0 };
    let Point { x, y } = point;
    
    let tuple = (1, 2, 3);
    let (first, _, third) = tuple;
}
```

### Loops

```phaser
fn loop_examples() {
    // Infinite loop with break
    let mut counter = 0;
    loop {
        counter += 1;
        if counter > 10 {
            break;
        }
    }
    
    // While loop
    let mut n = 0;
    while n < 5 {
        println!("n = {}", n);
        n += 1;
    }
    
    // For loop with range
    for i in 0..5 {
        println!("i = {}", i);
    }
    
    // For loop with collection
    let numbers = [1, 2, 3, 4, 5];
    for num in numbers {
        println!("num = {}", num);
    }
    
    // Labeled loops
    'outer: loop {
        'inner: loop {
            break 'outer; // Break out of outer loop
        }
    }
}
```

## Memory Management

### References and Borrowing

```phaser
fn borrowing_examples() {
    let mut data = vec![1, 2, 3, 4, 5];
    
    // Immutable borrow
    let len = calculate_length(&data);
    
    // Mutable borrow
    append_item(&mut data, 6);
    
    // Multiple immutable borrows allowed
    let first_ref = &data[0];
    let second_ref = &data[1];
    println!("First: {}, Second: {}", first_ref, second_ref);
}

fn calculate_length(list: &Vec<i32>) -> usize {
    list.len()
}

fn append_item(list: &mut Vec<i32>, item: i32) {
    list.push(item);
}
```

### Ownership

```phaser
fn ownership_examples() {
    let s1 = String::from("hello");
    let s2 = s1; // s1 is moved to s2
    // println!("{}", s1); // Error: s1 no longer valid
    
    let s3 = s2.clone(); // Explicit copy
    println!("s2: {}, s3: {}", s2, s3); // Both valid
    
    // Function takes ownership
    takes_ownership(s2);
    // println!("{}", s2); // Error: s2 moved into function
    
    // Function returns ownership
    let s4 = gives_ownership();
    println!("s4: {}", s4);
}

fn takes_ownership(s: String) {
    println!("Taking ownership of: {}", s);
} // s goes out of scope and is dropped

fn gives_ownership() -> String {
    String::from("returned string")
}
```

## Error Handling

### Result Type

```phaser
use std::fs::File;
use std::io::Error;

fn file_operations() -> Result<String, Error> {
    let mut file = File::open("example.txt")?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

fn error_handling_examples() {
    match file_operations() {
        Ok(contents) => println!("File contents: {}", contents),
        Err(error) => println!("Error reading file: {}", error),
    }
    
    // Using unwrap_or_else for default values
    let contents = file_operations()
        .unwrap_or_else(|_| "Default content".to_string());
}
```

### Custom Error Types

```phaser
#[derive(Debug)]
enum MathError {
    DivisionByZero,
    NegativeSquareRoot,
}

fn safe_divide(a: f64, b: f64) -> Result<f64, MathError> {
    if b == 0.0 {
        Err(MathError::DivisionByZero)
    } else {
        Ok(a / b)
    }
}

fn safe_sqrt(x: f64) -> Result<f64, MathError> {
    if x < 0.0 {
        Err(MathError::NegativeSquareRoot)
    } else {
        Ok(x.sqrt())
    }
}
```

## Traits and Generics

### Trait Definitions

```phaser
trait Drawable {
    fn draw(&self);
    
    // Default implementation
    fn description(&self) -> String {
        "A drawable object".to_string()
    }
}

trait Cloneable {
    fn clone(&self) -> Self;
}

// Trait with associated types
trait Iterator {
    type Item;
    
    fn next(&mut self) -> Option<Self::Item>;
}
```

### Trait Implementations

```phaser
impl Drawable for Point {
    fn draw(&self) {
        println!("Drawing point at ({}, {})", self.x, self.y);
    }
}

impl Drawable for Circle {
    fn draw(&self) {
        println!("Drawing circle at ({}, {}) with radius {}", 
                 self.center.x, self.center.y, self.radius);
    }
    
    fn description(&self) -> String {
        format!("Circle with radius {}", self.radius)
    }
}

// Generic implementation
impl<T: Clone> Cloneable for Vec<T> {
    fn clone(&self) -> Self {
        self.iter().cloned().collect()
    }
}
```

### Generic Functions and Structs

```phaser
// Generic function with trait bounds
fn print_drawable<T: Drawable>(item: &T) {
    println!("Description: {}", item.description());
    item.draw();
}

// Multiple trait bounds
fn process_item<T>(item: T) -> T 
where 
    T: Clone + Drawable + Debug 
{
    println!("Processing: {:?}", item);
    item.draw();
    item.clone()
}

// Generic struct with constraints
struct Pair<T, U> 
where 
    T: PartialEq,
    U: Display 
{
    first: T,
    second: U,
}
```

## Metaprogramming

### Compile-time Evaluation

```phaser
// Compile-time constants
const MAX_SIZE: usize = 1024;
const GREETING: &str = "Hello, Phaser!";

// Compile-time function evaluation
const fn factorial(n: u32) -> u32 {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}

const FACT_5: u32 = factorial(5); // Computed at compile time

// Comptime expressions
fn comptime_examples() {
    let size = comptime {
        if cfg!(debug_assertions) {
            1024
        } else {
            4096
        }
    };
    
    let array: [i32; comptime factorial(4)] = [0; 24];
}
```

### Meta Blocks

```phaser
meta {
    // Code generation at compile time
    for i in 0..5 {
        @generate_function(format!("func_{}", i));
    }
}

// Generated functions would be:
// fn func_0() { ... }
// fn func_1() { ... }
// fn func_2() { ... }
// fn func_3() { ... }
// fn func_4() { ... }
```

### Conditional Compilation

```phaser
fn platform_specific() {
    #[cfg(target_os = "windows")]
    {
        println!("Running on Windows");
    }
    
    #[cfg(target_os = "linux")]
    {
        println!("Running on Linux");
    }
    
    #[cfg(feature = "advanced")]
    {
        advanced_functionality();
    }
}

#[cfg(debug_assertions)]
fn debug_only_function() {
    println!("This only exists in debug builds");
}
```

## Async Programming

### Async Functions

```phaser
async fn fetch_data(url: &str) -> Result<String, HttpError> {
    let response = http_client::get(url).await?;
    let body = response.text().await?;
    Ok(body)
}

async fn process_multiple_requests() {
    let urls = vec![
        "https://api.example.com/data1",
        "https://api.example.com/data2",
        "https://api.example.com/data3",
    ];
    
    let futures: Vec<_> = urls.into_iter()
        .map(|url| fetch_data(url))
        .collect();
    
    let results = futures::join_all(futures).await;
    
    for result in results {
        match result {
            Ok(data) => println!("Received: {}", data),
            Err(error) => println!("Error: {}", error),
        }
    }
}
```

### Async Blocks

```phaser
fn async_block_example() {
    let future = async {
        let data = fetch_data("https://api.example.com").await?;
        process_data(data).await
    };
    
    // Execute the future
    let result = runtime::block_on(future);
}
```

## Module System

### Module Definition

```phaser
// In src/math/mod.ph
pub mod geometry;
pub mod algebra;

pub use geometry::Point;
pub use algebra::Matrix;

pub fn common_function() {
    println!("Common math function");
}
```

### Module Usage

```phaser
// In src/main.ph
mod math;

use math::{Point, Matrix};
use math::geometry::Circle;

fn main() {
    let point = Point::new(1.0, 2.0);
    let matrix = Matrix::identity(3);
    let circle = Circle::new(point, 5.0);
    
    math::common_function();
}
```

## Advanced Features

### Unsafe Code

```phaser
unsafe fn raw_pointer_example() {
    let mut x = 42;
    let raw_ptr = &mut x as *mut i32;
    
    // Dereferencing raw pointers requires unsafe
    *raw_ptr = 100;
    
    println!("x = {}", x); // x = 100
}

fn safe_wrapper() {
    // Unsafe code should be wrapped in safe abstractions
    unsafe {
        raw_pointer_example();
    }
}
```

### Foreign Function Interface (FFI)

```phaser
extern "C" {
    fn abs(input: i32) -> i32;
    fn sqrt(input: f64) -> f64;
}

fn ffi_example() {
    let x = -42;
    let abs_x = unsafe { abs(x) };
    
    let y = 16.0;
    let sqrt_y = unsafe { sqrt(y) };
    
    println!("abs({}) = {}, sqrt({}) = {}", x, abs_x, y, sqrt_y);
}
```

This comprehensive set of examples demonstrates the practical application of Phaser's syntax and features as defined in the [[Grammar Specification]]. The examples follow the [[Design Principles]] of explicitness, readability, and safety while showcasing the language's power and flexibility.