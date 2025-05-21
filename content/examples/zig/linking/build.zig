pub fn build(b: *std.Build) !void {

const steps = .{
    .lib_build = b.step("build:lib", "Builds the library."),
    .rust_client = b.step("clients:rust", "Builds Rust Client with lib"),
    .python_client = b.step("clients:python", "Builds Python Client with lib"),
};

}
