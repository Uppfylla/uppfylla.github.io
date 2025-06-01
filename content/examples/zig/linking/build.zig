const std = @import("std"); //  Zig's standard library
const assert = std.debug.assert; // Assert!
const builtin = @import("builtin"); // Builtins
const log = std.log.scoped(.build_log); // Scoped log, not 100% necessary in this example but we believe that it's a good practice.

comptime {
    const zigv_comp = builtin.zig_version.major == 0 and
        builtin.zig_version.minor == 14 and
        builtin.zig_version.patch == 0;
    if (!zigv_comp) {
        @compileError(std.fmt.comptimePrint("Zig version unsupported found {} expected 0.14.0", .{ builtin.zig_version },));
    }
}

fn build_lib(
    b: *std.Build,
    steps: *std.Build.Step,
    options: struct {
        optimize: std.builtin.OptimizeMode,
    },
) void{


    const query = std.Target.Query.parse(.{
            .arch_os_abi = "x86_64-linux-gnu.2.27",
            .cpu_features = "x86_64_v3+aes",
    }) catch unreachable;
    const resolved_target = b.resolveTargetQuery(query);

    //const shared_lib = b.addSharedLibrary(.{
    //    .name = "lib",
    //    .root_source_file = b.path("src/root.zig"),
    //    .target = options.target,
    //    .optimize = options.optimize,
    //});

    //shared_lib.linkLibC();

    //const static_lib = b.addStaticLibrary(.{
    //    .name = "lib",
    //    .root_source_file = b.path("src/root.zig"),
    //    .target = options.target,
    //    .optimize = options.optimize,
    //});

    //static_lib.pie = true;
    //static_lib.bundle_compiler_rt = true;
    //static_lib.linkLibC();

    const shared = b.addSharedLibrary(.{
            .name = "add",
            .root_source_file = b.path("src/root.zig"),
            .target = resolved_target,
            .optimize = options.optimize,
    });
    shared.linkLibC();
    log.info("Creating shared lib {s}", .{
        b.pathJoin(&.{
            "./src/clients/lib/",
            "x86_64-linux-gnu.2.27",
            shared.out_filename,
            })});
    steps.dependOn(&b.addInstallFile(
            shared.getEmittedBin(),
            b.pathJoin(&.{
            "../src/clients/lib/",
            "x86_64-linux-gnu.2.27",
            shared.out_filename,
            }),
    ).step);

    const static = b.addStaticLibrary(.{
            .name = "add",
            .root_source_file = b.path("src/root.zig"),
            .target = resolved_target,
            .optimize = options.optimize,
    });

    static.pie = true;
    static.bundle_compiler_rt = true;
    static.linkLibC();
    log.info("Creating static lib {s}", .{
        b.pathJoin(&.{
            "./src/clients/lib/",
            "x86_64-linux-gnu.2.27",
            static.out_filename,
            })});
    steps.dependOn(&b.addInstallFile(
            static.getEmittedBin(),
            b.pathJoin(&.{
            "../src/clients/lib/",
            "x86_64-linux-gnu.2.27",
            static.out_filename,
            }),
    ).step);

    // In case we'd like to add a module to the lib, we could do for example;
    //const util_mod = b.createModule(.{ .root_source_file = b.path("src/lib/util.zig") });
    //lib.root_module.addImport("util", util_mod);


    // Specify path to link libs..

    //step.dependOn(&lib.step);
    //return lib;
}

fn build_python_client(b: *std.Build, steps: *std.Build.Step) void {

const PythonBuildStep = struct {
    source: std.Build.LazyPath,
    step: std.Build.Step,

    // Ofcourse this could become more generic..
    fn make_python(step: *std.Build.Step, prog_node: std.Build.Step.MakeOptions) anyerror!void {
            _ = prog_node; // Not needed in this example..
            const _b = step.owner;
            const py: *@This() = @fieldParentPtr("step", step);
            const source_path = py.source.getPath2(_b, step);
            const p = try std.fs.Dir.updateFile(
                    _b.build_root.handle,
                    source_path,
                    _b.build_root.handle,
                    "./src/clients/python/src/bindings.py",
                    .{},);
            step.result_cached = p == .fresh;
    }

    pub fn init(_b: *std.Build) *@This() {
        const build_step = _b.allocator.create(@This()) catch @panic("Out of memory!");
        build_step.* = .{
                .source = _b.addRunArtifact(_b.addExecutable(.{
                .name = "python_bindings",
                .root_source_file = _b.path("src/clients/python/bindings.zig"),
                .target = _b.graph.host,
        })).captureStdOut(),
                .step = std.Build.Step.init(.{ // Initialize a build step.
                        .id = .custom,
                        .name = _b.fmt("generate {s}", .{std.fs.path.basename("./src/clients/python/src/bindings.py")}),
                        .owner = _b,
                        .makeFn = make_python, // This could ofcourse be more elegant, e.g. have a struct for all generated code with member functions...
                }),
        };

        build_step.source.addStepDependencies(&build_step.step);
        return build_step;
    }
};

        const bindings = PythonBuildStep.init(
                b,
        );

        steps.dependOn(&bindings.step);

}

fn build_rust_client(b: *std.Build, steps: *std.Build.Step ) void {

const RustBuildStep = struct {
    source: std.Build.LazyPath,
    step: std.Build.Step,

    // Ofcourse this could become more generic..
    fn make_rust(step: *std.Build.Step, prog_node: std.Build.Step.MakeOptions) anyerror!void {
            _ = prog_node; // Not needed in this example..
            const _b = step.owner;
            const py: *@This() = @fieldParentPtr("step", step);
            const source_path = py.source.getPath2(_b, step);
            const p = try std.fs.Dir.updateFile(
                    _b.build_root.handle,
                    source_path,
                    _b.build_root.handle,
                    "./src/clients/rust/src/lib.rs",
                    .{},);
            step.result_cached = p == .fresh;
    }

    pub fn init(_b: *std.Build) *@This() {
        const build_step = _b.allocator.create(@This()) catch @panic("Out of memory!");
        build_step.* = .{
                .source = _b.addRunArtifact(_b.addExecutable(.{
                .name = "rust_bindings",
                .root_source_file = _b.path("src/clients/rust/bindings.zig"),
                .target = _b.graph.host,
        })).captureStdOut(),
                .step = std.Build.Step.init(.{ // Initialize a build step.
                        .id = .custom,
                        .name = _b.fmt("Generate rust : {s}", .{std.fs.path.basename("./src/clients/rust/src/lib.rs")}),
                        .owner = _b,
                        .makeFn = make_rust, // This could ofcourse be more elegant, e.g. have a struct for all generated code with member functions...
                }),
        };
        build_step.source.addStepDependencies(&build_step.step);
        return build_step;
    }
};

        const bindings = RustBuildStep.init(
                b,
        );
        steps.dependOn(&bindings.step);

}

pub fn build(b: *std.Build) !void {

        const steps = .{
                .build_lib = b.step("lib", "Builds the library."),
                .rust_client = b.step("clients:rust", "Builds Rust Client with lib"),
                .python_client = b.step("clients:python", "Builds Python Client with lib"),
        };

        const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

        build_lib(b, steps.build_lib, .{
                .optimize = optimize,
        });

        // E.g. python client
        build_python_client(b, steps.python_client);

        // E.g. rust client
        build_rust_client(b, steps.rust_client);

}
