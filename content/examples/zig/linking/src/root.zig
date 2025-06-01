// Tangled from content/org/blog.org
const std = @import("std"); // Importing standard lib
const builtin = @import("builtin"); // Builtins

comptime { // Run this at compile time.
    if (!builtin.link_libc) { // Require libc
        @compileError("Symbols cannot be exported without libc.");
    }
    // Creates a symbol in the output object file which refers to the target of add function. Essentially this is equivalent to the export keyword used on a function.
    @export(&add, .{ .name = "zig_add", .linkage = .strong });
}

// Our add function with C calling conventions, ensuring our function can be called correctly from other languages.
pub fn add(a: i32, b: i32) callconv(.C) i32 {
    return a + b;
}
