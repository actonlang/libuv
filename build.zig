const std = @import("std");
const print = @import("std").debug.print;
const tgt = @import("builtin").target;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const t = target.result;

    const lib = b.addStaticLibrary(.{
        .name = "uv",
        .target = target,
        .optimize = optimize,
    });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();

    if (t.os.tag == .windows) {
        flags.appendSlice(&.{
            "-D_FILE_OFFSET_BITS=64",
            "-D_LARGEFILE_SOURCE",
        }) catch unreachable;
    }

    if (t.os.tag == .linux) {
        flags.appendSlice(&.{
            "-D_GNU_SOURCE",
            "-D_POSIX_C_SOURCE=200112",
        }) catch unreachable;
    }

    if (t.isDarwin()) {
        flags.appendSlice(&.{
            "-D_DARWIN_UNLIMITED_SELECT=1",
            "-D_DARWIN_USE_64_BIT_INODE=1",
        }) catch unreachable;
    }


    lib.addCSourceFiles(.{
        .files = &.{
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
        },
        .flags = flags.items
    });

    if (t.os.tag == .windows) {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/win/async.c",
                "src/win/core.c",
                "src/win/detect-wakeup.c",
                "src/win/dl.c",
                "src/win/error.c",
                "src/win/fs.c",
                "src/win/fs-event.c",
                "src/win/getaddrinfo.c",
                "src/win/getnameinfo.c",
                "src/win/handle.c",
                "src/win/loop-watcher.c",
                "src/win/pipe.c",
                "src/win/thread.c",
                "src/win/poll.c",
                "src/win/process.c",
                "src/win/process-stdio.c",
                "src/win/signal.c",
                "src/win/snprintf.c",
                "src/win/stream.c",
                "src/win/tcp.c",
                "src/win/tty.c",
                "src/win/udp.c",
                "src/win/util.c",
                "src/win/winapi.c",
                "src/win/winsock.c"
            },
            .flags = flags.items
        });
    } else {
        lib.addCSourceFiles(.{
            .files = &.{
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
            },
            .flags = flags.items
        });
    }

    if (t.os.tag == .linux or t.isDarwin()) {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/unix/proctitle.c",
            },
            .flags = flags.items
        });
    }

    if (t.os.tag == .linux) {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/unix/linux.c",
                "src/unix/procfs-exepath.c",
                "src/unix/random-getrandom.c",
                "src/unix/random-sysctl-linux.c",
            },
            .flags = flags.items
        });
    }

    if (t.isDarwin() or
        t.isBSD())
    {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/unix/bsd-ifaddrs.c",
                "src/unix/kqueue.c",
            },
            .flags = flags.items
        });
    }

    if (t.isDarwin() or t.os.tag == .openbsd) {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/unix/random-getentropy.c",
            },
            .flags = flags.items
        });
    }

    if (t.isDarwin()) {
        lib.addCSourceFiles(.{
            .files = &.{
                "src/unix/darwin-proctitle.c",
                "src/unix/darwin.c",
                "src/unix/fsevents.c",
            },
            .flags = flags.items
        });
    }

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));
    if (t.os.tag == .windows) {
        lib.linkSystemLibrary("psapi");
        lib.linkSystemLibrary("user32");
        lib.linkSystemLibrary("advapi32");
        lib.linkSystemLibrary("iphlpapi");
        lib.linkSystemLibrary("userenv");
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("dbghelp");
        lib.linkSystemLibrary("ole32");
        lib.linkSystemLibrary("uuid");
    }
    lib.linkLibC();

    b.installDirectory(std.Build.Step.InstallDir.Options{
        .source_dir = b.path("include"),
        .install_dir = .header,
        .install_subdir = "",
    });
    b.installArtifact(lib);
}
