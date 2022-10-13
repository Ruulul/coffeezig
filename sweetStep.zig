const std = @import("std");

const Self = @This();

step: std.build.Step,
builder: *std.build.Builder,
source: std.build.FileSource,

output_file: std.build.GeneratedFile,

pub fn createFile(b: *std.build.Builder, file: []const u8) *Self {
    return createSourceFile(b, .{ .path = file });
}

pub fn createSourceFile(b: *std.build.Builder, source: std.build.FileSource) *Self {
    const self = b.allocator.create(Self) catch unreachable;
    self.* = .{
        .step = std.build.Step.init(.custom, "coffee-zig", b.allocator, make),
        .builder = b,
        .source = source,

        .output_file = std.build.GeneratedFile{ .step = &self.step },
    };

    source.addStepDependencies(&self.step);
    
    return self;
}

fn make(step: *std.build.Step) !void {
    const self = @fieldParentPtr(Self, "step", step);

    const source_file_name = self.source.getPath(self.builder);
    _ = source_file_name;
}