const std = @import("std");
const SweetStep = @import("SweetStep.zig");


pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("coffeezig", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    var sweet_steps: []SweetStep = &.{};
{
    const path = "src";
    var root = std.fs.cwd().openIterableDir(path, .{}) 
        catch |e| {
            std.log.err(
            \\Error when trying to access folder 
            \\{s}
            \\, are you sure thats the correct folder to your .czig files?
            \\
            \\{s}
            , .{ path, @errorName(e) }); 
            return;
        };
    defer root.close();
    var sweet_list = std.ArrayList(SweetStep).init(b.allocator);
    defer sweet_steps = sweet_list.toOwnedSlice();
    var iterable = root.iterate();
    while (iterable.next() catch |e| {
        std.log.err("Error during walk files: {s}", .{@errorName(e)});
        return;
    }) |file| {
        const dot_index = std.mem.indexOf(u8, file.name, ".") orelse continue;
        const ext = file.name[dot_index..];
        if (!std.mem.eql(u8, ext, ".czig")) continue;

        const sweet_step = SweetStep.createFile(b, 
        std.mem.join(b.allocator, "/", &.{path, file.name})
        catch |e| {
            std.log.err("Error while baking file {s}: {s}", .{file.name, @errorName(e)});
            continue;
        });

        sweet_list.append(sweet_step.*) catch |e| {
            std.log.err("Error while baking file {s}: {s}", .{file.name, @errorName(e)});
            continue;
        };

        exe.addPackage(.{
            .name = file.name,
            .source = .{ .path = sweet_step.output_file.getPath() },
        });
    }
}

    const run_cmd = exe.run();
    for (sweet_steps) |*sweet_step| run_cmd.step.dependOn(&sweet_step.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
