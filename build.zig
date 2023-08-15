const std = @import("std");
const print = @import("std").debug.print;
const tgt = @import("builtin").target;

pub fn build(b: *std.build.Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary(.{
        .name = "uv",
        .target = target,
        .optimize = optimize,
    });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();

    if (!target.isWindows()) {
        flags.appendSlice(&.{
            "-D_FILE_OFFSET_BITS=64",
            "-D_LARGEFILE_SOURCE",
        }) catch |err| {
            std.log.err("Error appending iterable dir: {}", .{err});
            std.os.exit(1);
        };
    }

    if (target.isLinux()) {
        flags.appendSlice(&.{
            "-D_GNU_SOURCE",
            "-D_POSIX_C_SOURCE=200112",
        }) catch |err| {
            std.log.err("Error appending iterable dir: {}", .{err});
            std.os.exit(1);
        };
    }

    if (target.isDarwin()) {
        flags.appendSlice(&.{
            "-D_DARWIN_UNLIMITED_SELECT=1",
            "-D_DARWIN_USE_64_BIT_INODE=1",
        }) catch |err| {
            std.log.err("Error appending iterable dir: {}", .{err});
            std.os.exit(1);
        };
    }


    lib.addCSourceFiles(&.{
        "src/fs-poll.c",
        "src/idna.c",
        "src/inet.c",
        "src/random.c",
        "src/strscpy.c",
        "src/strtok.c",
        "src/threadpool.c",
        "src/timer.c",
        "src/uv-common.c",
        "src/uv-data-getter-setters.c",
        "src/version.c",
        }, flags.items);

    if (!target.isWindows()) {
        lib.addCSourceFiles(&.{
            "src/unix/async.c",
            "src/unix/core.c",
            "src/unix/dl.c",
            "src/unix/fs.c",
            "src/unix/getaddrinfo.c",
            "src/unix/getnameinfo.c",
            "src/unix/loop-watcher.c",
            "src/unix/loop.c",
            "src/unix/pipe.c",
            "src/unix/poll.c",
            "src/unix/process.c",
            "src/unix/random-devurandom.c",
            "src/unix/signal.c",
            "src/unix/stream.c",
            "src/unix/tcp.c",
            "src/unix/thread.c",
            "src/unix/tty.c",
            "src/unix/udp.c",
        }, flags.items);
    }

    if (target.isLinux() or target.isDarwin()) {
        lib.addCSourceFiles(&.{
            "src/unix/proctitle.c",
        }, flags.items);
    }

    if (target.isLinux()) {
        lib.addCSourceFiles(&.{
            "src/unix/linux.c",
            "src/unix/procfs-exepath.c",
            "src/unix/random-getrandom.c",
            "src/unix/random-sysctl-linux.c",
        }, flags.items);
    }

    if (target.isDarwin() or
        target.isOpenBSD() or
        target.isNetBSD() or
        target.isFreeBSD() or
        target.isDragonFlyBSD())
    {
        lib.addCSourceFiles(&.{
            "src/unix/bsd-ifaddrs.c",
            "src/unix/kqueue.c",
        }, flags.items);
    }

    if (target.isDarwin() or target.isOpenBSD()) {
        lib.addCSourceFiles(&.{
            "src/unix/random-getentropy.c",
        }, flags.items);
    }

    if (target.isDarwin()) {
        lib.addCSourceFiles(&.{
            "src/unix/darwin-proctitle.c",
            "src/unix/darwin.c",
            "src/unix/fsevents.c",
        }, flags.items);
    }

    lib.addIncludePath(.{ .path = "src" });
    lib.addIncludePath(.{ .path = "include" });
    lib.linkLibC();

    b.installDirectory(std.Build.InstallDirectoryOptions{
        .source_dir = .{ .path = "include" },
        .install_dir = .header,
        .install_subdir = "",
    });
    b.installArtifact(lib);
}
