const std = @import("std");

const Options = @import("../../build.zig").Options;

const demo_name = "minimal_zgui_win32_d3d12";
const content_dir = demo_name ++ "_content/";

pub fn build(b: *std.Build, options: Options) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = demo_name,
        .root_source_file = .{ .path = thisDir() ++ "/src/" ++ demo_name ++ ".zig" },
        .target = options.target,
        .optimize = options.optimize,
    });

    @import("system_sdk").addLibraryPathsTo(exe);

    const zwin32 = b.dependency("zwin32", .{
        .target = options.target,
    });
    const zwin32_module = zwin32.module("root");
    exe.root_module.addImport("zwin32", zwin32_module);

    const zd3d12 = b.dependency("zd3d12", .{
        .target = options.target,
        .debug_layer = options.zd3d12_enable_debug_layer,
        .gbv = options.zd3d12_enable_gbv,
    });
    const zd3d12_module = zd3d12.module("root");
    exe.root_module.addImport("zd3d12", zd3d12_module);

    const zgui = b.dependency("zgui", .{
        .target = options.target,
        .backend = .win32_dx12,
    });
    exe.root_module.addImport("zgui", zgui.module("root"));
    exe.linkLibrary(zgui.artifact("imgui"));

    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);
    exe_options.addOption([]const u8, "content_dir", content_dir);

    const install_content_step = b.addInstallDirectory(.{
        .source_dir = .{ .path = thisDir() ++ "/" ++ content_dir },
        .install_dir = .{ .custom = "" },
        .install_subdir = "bin/" ++ content_dir,
    });
    exe.step.dependOn(&install_content_step.step);

    exe.rdynamic = true;

    @import("zwin32").install_d3d12(&exe.step, .bin, "libs/zwin32") catch unreachable;

    return exe;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
