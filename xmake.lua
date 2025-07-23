set_project("moduletest")
set_version("v0.2")
set_languages("c++latest")

set_policy("build.c++.modules", true)

local qemu_args = {
    "-accel", "kvm",
    "-m", "256",
    "-cdrom", "boot.iso",
    "-serial", "stdio",
    "-d", "int", "-D", "log.txt", "-no-reboot" }

toolchain("dos-clang")
set_kind("standalone")
set_toolset("cc", "clang")
set_toolset("cxx", "clang++")
set_toolset("as", "clang")
set_toolset("ld", "ld.lld", "lld")
set_toolset("strip", "strip")

--includes("contrib/xmake.lua")

on_load(function(toolchain)
    local cx_args = {
        "-ffreestanding",
        "-fno-stack-protector",
        "-fno-omit-frame-pointer",
        "-fno-strict-aliasing",
        "-fstrict-vtable-pointers",
        "-mno-red-zone",
        '-mno-mmx',
        "-mno-sse",
        "-mno-sse2",
        "-mno-80387",
        "-mcmodel=kernel",
        "-nostdinc",
        "-Wall",
        "-masm=intel",
        "-Icontrib",
        "-Wno-include-angled-in-module-purview"
    }

    local c_args = {}
    local cxx_args = {
        "-fno-rtti",
        "-fno-exceptions"
    }

    local ld_args = {
        "-nostdlib",
        "-static",
        "-zmax-page-size=0x1000"
    }

    toolchain:add("cxxflags", cxx_args, { force = true })
    toolchain:add("cxxflags", cx_args, { force = true })
    toolchain:add("cflags", c_args, { force = true })
    toolchain:add("cflags", cx_args, { force = true })
    toolchain:add("asflags", cx_args, { force = true })
    toolchain:add("ldflags", ld_args, { force = true })
end)

target("kernel.elf")
set_toolchains("@dos-clang")
--add_includedirs("include")
add_cxxflags("-Os")
set_kind("binary")
add_files("source/**.S")
add_files("source/**.cc", { public = true })
add_ldflags("-T" .. "$(projectdir)/source/x86_64/linker.ld", { force = true })

target("iso")
set_default(true)
add_deps("kernel.elf")

on_load(function(project)
    os.tryrm(path.join("boot.iso"))
end)

on_build(function(project)
    targetfile         = path.join("boot.iso")

    --local kernel       = project.target("kernel.elf")

    local iso_dirname  = "iso_root"
    local iso_dir      = path.join('.', iso_dirname)
    local iso_dir_b    = path.join(iso_dir, "boot")
    local iso_dir_bl   = path.join(iso_dir, "boot/limine")

    local limine_files = {
        "$(projectdir)/misc/limine.conf"
    }

    local xorriso_args = {
        "-as", "mkisofs", "-b", "boot/limine/limine-bios-cd.bin",
        "-no-emul-boot", "-boot-load-size", "4",
        "-boot-info-table", iso_dir, "-o", targetfile
    }

    local function create_iso()
        os.tryrm(targetfile)
        os.tryrm(iso_dir)

        os.mkdir(iso_dir)
        os.mkdir(iso_dir_b)
        os.mkdir(iso_dir_bl)

        os.cp(path.join("build/linux/x86_64/release/kernel.elf"), path.join(iso_dir_b))
        os.cp(path.join("contrib/limine/limine-bios.sys"), path.join(iso_dir_bl))
        os.cp(path.join("contrib/limine/limine-bios-cd.bin"), path.join(iso_dir_bl))
        os.cp(path.join("misc/limine.conf"), path.join(iso_dir_bl))

        os.execv("xorriso", xorriso_args)
    end

    if not created and not os.isfile(targetfile) then
        create_iso()
    end
end)

target("run")
add_deps("iso")
on_build(function(target)
    os.execv("qemu-system-x86_64", qemu_args)
end)
