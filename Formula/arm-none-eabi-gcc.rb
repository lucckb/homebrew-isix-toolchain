require "formula"

class ArmNoneEabiGcc < Formula
  desc "GNU C/C++ compiler for OS-less ARM 32-bit architecture"
  homepage "https://gcc.gnu.org"
  url 'http://ftpmirror.gnu.org/gcc/gcc-10.3.0/gcc-10.3.0.tar.xz'
  sha256 '64f404c1a650f27fc33da242e1f2df54952e3963a49e06e73f6940f3223ac344'
  patch :p2, :DATA

  depends_on "arm-none-eabi-binutils"
  depends_on "gmp"
  depends_on "isl"
  depends_on "libelf"
  depends_on "libmpc"
  depends_on "mpfr"

  resource "newlib" do
    url "ftp://sourceware.org/pub/newlib/newlib-4.1.0.tar.gz"
    sha256 "f296e372f51324224d387cc116dc37a6bd397198756746f93a2b02e9a5d40154"
  end

  def install
    xtarget = "arm-none-eabi"
    xbinutils = xtarget + "-binutils"

    coredir = Dir.pwd

    resource("newlib").stage do
      cp_r Dir.pwd+"/newlib", coredir+"/newlib"
    end

    gmp = Formulary.factory "gmp"
    mpfr = Formulary.factory "mpfr"
    libmpc = Formulary.factory "libmpc"
    libelf = Formulary.factory "libelf"
    isl = Formulary.factory "isl"
    binutils = Formulary.factory xbinutils

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV["CFLAGS_FOR_BUILD"] = "-O2"
    ENV["CFLAGS"] = "-O2"
    ENV["CFLAGS_FOR_TARGET"] = "-O2"
    ENV["CXXFLAGS_FOR_BUILD"] = "-O2"
    ENV["CXXFLAGS"] = "-O2"
    ENV["CXXFLAGS_FOR_TARGET"] = "-O2"

    build_dir="build"
    mkdir build_dir
    Dir.chdir build_dir do
      system coredir+"/configure",
          "--prefix=#{prefix}", "--target=#{xtarget}",
          "--libdir=#{lib}/gcc/#{xtarget}",
          "--disable-shared", "--with-gnu-as", "--with-gnu-ld",
          "--with-newlib", "--enable-softfloat", "--disable-bigendian",
          "--disable-fpu", "--disable-underscore", "--enable-multilibs",
          "--with-float=soft", "--enable-interwork", "--enable-lto",
          "--with-multilib", "--enable-plugins",
          "--with-abi=aapcs", "--enable-languages=c,c++",
          "--with-gmp=#{gmp.opt_prefix}",
          "--with-mpfr=#{mpfr.opt_prefix}",
          "--with-mpc=#{libmpc.opt_prefix}",
          "--with-isl=#{isl.opt_prefix}",
          "--with-libelf=#{libelf.opt_prefix}",
          "--with-gxx-include-dir=#{prefix}/#{xtarget}/c++/include",
          "--enable-checking=release",
          "--disable-clocale",
          "--disable-libstdcxx-time",
          "--disable-libstdcxx-threads",
          "--disable-nls",
          "--disable-libstdcxx-verbose",
          "--disable-libstdcxx-dual-abi",
          "--disable-wchar_t",
		  "--disable-vtable-verify",
          "--enable-multilib",
          "--disable-newlib-supplied-syscalls",
		  "--enable-newlib-reent-small",
		  "--disable-newlib-fvwrite-in-streamio",
		  "--disable-newlib-fseek-optimization",
		  "--disable-newlib-wide-orient",
		  "--enable-newlib-nano-malloc",
          "--disable-newlib-unbuf-stream-opt",
		  "--enable-target-optspace",
		  "--enable-newlib-io-float",
		  "--disable-newlib-fvwrite-in-streamio",
		  "--disable-newlib-wide-orient",
		  "--enable-newlib-nano-malloc",
          "--disable-newlib-unbuf-stream-opt",
          "--enable-newlib-nano-formatted-io",
          "--enable-newlib-retargetable-locking"
	


      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/#{xtarget}/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/arm-none-eabi-/'); done)"
    end

    ln_s "#{binutils.prefix}/#{xtarget}/bin",
         "#{prefix}/#{xtarget}/bin"
  end
end
__END__
--- ./gcc-9.1.0/gcc/config/arm/t-arm-elf	2019-01-01 13:31:55.000000000 +0100
+++ ./gcc-8.2.0/gcc/config/arm/t-arm-elf	2019-06-21 10:00:31.378862283 +0200
@@ -1,4 +1,4 @@
-# Copyright (C) 1998-2020 Free Software Foundation, Inc.
+# Copyright (C) 1998-2020 Free Software Foundation, Inc. (BoFF Mod)
 #
 # This file is part of GCC.
 #
@@ -16,111 +16,45 @@
 # along with GCC; see the file COPYING3.  If not see
 # <http://www.gnu.org/licenses/>.
 
-# Build a very basic set of libraries that should cater for most cases.
+MULTILIB_OPTIONS     = marm/mthumb
+MULTILIB_DIRNAMES    = arm thumb
+MULTILIB_EXCEPTIONS  = marm mthumb
 
-# Single-precision floating-point is NOT supported; we don't build a
-# suitable library for that.  Use the rm-profile config in that case.
 
-# PART 1 - Useful groups of options
 
-dp_fpus		:= vfp vfpv2 vfpv3 vfpv3-fp16 vfpv3-d16 vfpv3-d16-fp16 \
-		   neon neon-vfpv3 neon-fp16 vfpv4 neon-vfpv4 vfpv4-d16 \
-		   fpv5-d16 fp-armv8 neon-fp-armv8 crypto-neon-fp-armv8 \
-		   vfp3
+MULTILIB_OPTIONS += mcpu=arm7tdmi-s/mcpu=cortex-m0/mcpu=cortex-m0plus/mcpu=cortex-m0.small-multiply/mcpu=cortex-m0plus.small-multiply/mcpu=cortex-m3/mcpu=cortex-m4/mcpu=cortex-m7
+MULTILIB_DIRNAMES  += arm7tdmi_s cortex_m0 cortex_m0plus cortex_m0_smul cortex_m0plus_smul cortex_m3 cortex_m4 cortex_m7
 
-sp_fpus		:= vfpv3xd vfpv3xd-fp16  fpv4-sp-d16 fpv5-sp-d16
+# Don't build arm version for Cortex cores
+MULTILIB_EXCEPTIONS +=  *marm*/*mcpu=cortex-m*
 
-v7a_fps		:= vfpv3 vfpv3-fp16 vfpv4 simd neon-fp16 neon-vfpv4
-v7ve_fps	:= vfpv3-d16 vfpv3 vfpv3-d16-fp16 vfpv3-fp16 vfpv4 neon \
-		   neon-fp16 simd
 
-# Not all these permutations exist for all architecture variants, but
-# it seems to work ok.
-v8_fps		:= simd fp16 crypto fp16+crypto dotprod fp16fml
+# Support FPU devices for Cortex M4/M7 cores
+MULTILIB_OPTIONS  += mfloat-abi=hard  mfpu=fpv4-sp-d16/mfpu=fpv5-d16/mfpu=fpv5-sp-d16
+MULTILIB_DIRNAMES += float_abi_hard fpv4_sp_d16 fpv5_d16 fpv5_sp_d16
+MULTILIB_EXCEPTIONS += marm/mfloat* mfloat* mthumb/mfloat*
+MULTILIB_EXCEPTIONS += mfpu* mthumb/mfpu*
+MULTILIB_EXCEPTIONS += mcpu*/mfloat*
+MULTILIB_EXCEPTIONS +=  *arm7tdmi-s*mfloat-abi* *arm7tdmi-s*mfpu*
+MULTILIB_EXCEPTIONS += *cortex-m0*mfloat-abi* *cortex-m0*mfpu*
+MULTILIB_EXCEPTIONS += *cortex-m0plus*mfloat-abi* *cortex-m0plus*mfpu*
+MULTILIB_EXCEPTIONS += *cortex-m0.small-multiply*mfloat-abi* *cortex-m0.small-multiply*mfpu*
+MULTILIB_EXCEPTIONS += *cortex-m0plus.small-multiply*mfloat-abi* *cortex-m0plus.small-multiply*mfpu*
+MULTILIB_EXCEPTIONS += *cortex-m3*mfloat-abi* *cortex-m3*mfpu*
+MULTILIB_EXCEPTIONS += mcpu=cortex-m* mfpu*
+MULTILIB_EXCEPTIONS  += marm/mfpu* marm/mcpu*
+# Exclude -mfloat-abi=hard without -mfpu option and viceversa
+MULTILIB_EXCEPTIONS += mthumb/mcpu=cortex-m4/mfloat-abi=hard
+MULTILIB_EXCEPTIONS += mthumb/mcpu=cortex-m4/mfpu=fpv4-sp-d16
+MULTILIB_EXCEPTIONS += mthumb/mcpu=cortex-m7/mfloat-abi=hard
+MULTILIB_EXCEPTIONS += mthumb/mcpu=cortex-m7/mfpu=fpv5-sp-d16
+MULTILIB_EXCEPTIONS += mthumb/mcpu=cortex-m7/mfpu=fpv5-d16
+# Exclude VFP V5 from cortex M4
+MULTILIB_EXCEPTIONS += *mcpu=cortex-m4*mfpu=fpv5*-d16
+MULTILIB_EXCEPTIONS += *mcpu=cortex-m7*mfpu=fpv4*-d16
 
-# We don't do anything special with these.  Pre-v4t probably doesn't work.
-all_early_nofp	:= armv4 armv4t armv5t
 
-all_early_arch	:= armv5tej armv6 armv6j armv6k armv6z armv6kz \
-		   armv6zk armv6t2 iwmmxt iwmmxt2
 
-all_v7_a_r	:= armv7-a armv7ve armv7-r
 
-all_v8_archs	:= armv8-a armv8-a+crc armv8.1-a armv8.2-a armv8.3-a armv8.4-a \
-		   armv8.5-a armv8.6-a
 
-# No floating point variants, require thumb1 softfp
-all_nofp_t	:= armv6-m armv6s-m armv8-m.base
-
-all_nofp_t2	:= armv7-m
-
-all_sp_only	:= armv7e-m armv8-m.main
-
-MULTILIB_OPTIONS     =
-MULTILIB_DIRNAMES    =
-MULTILIB_EXCEPTIONS  = 
-MULTILIB_MATCHES     =
-MULTILIB_REUSE	     =
-
-# PART 2 - multilib build rules
-
-MULTILIB_OPTIONS     += marm/mthumb
-MULTILIB_DIRNAMES    += arm thumb
-
-MULTILIB_OPTIONS     += mfpu=auto
-MULTILIB_DIRNAMES    += autofp
-
-MULTILIB_OPTIONS     += march=armv5te+fp/march=armv7+fp
-MULTILIB_DIRNAMES    += v5te v7
-
-MULTILIB_OPTIONS     += mfloat-abi=hard
-MULTILIB_DIRNAMES    += fpu
-
-# Build a total of 4 library variants (base options plus the following):
-MULTILIB_REQUIRED    += mthumb
-MULTILIB_REQUIRED    += marm/mfpu=auto/march=armv5te+fp/mfloat-abi=hard
-MULTILIB_REQUIRED    += mthumb/mfpu=auto/march=armv7+fp/mfloat-abi=hard
-
-# PART 3 - Match rules
-
-# Map all supported FPUs onto mfpu=auto
-MULTILIB_MATCHES     += $(foreach FPU, $(dp_fpus), \
-			  mfpu?auto=mfpu?$(FPU))
-
-MULTILIB_MATCHES     += march?armv5te+fp=march?armv5te
-
-MULTILIB_MATCHES     += $(foreach ARCH, $(all_early_arch), \
-		          march?armv5te+fp=march?$(ARCH) \
-			  march?armv5te+fp=march?$(ARCH)+fp)
-
-MULTILIB_MATCHES     += march?armv7+fp=march?armv7
-
-MULTILIB_MATCHES     += $(foreach FPARCH, $(v7a_fps), \
-		          march?armv7+fp=march?armv7-a+$(FPARCH))
-
-MULTILIB_MATCHES     += $(foreach FPARCH, $(v7ve_fps), \
-		          march?armv7+fp=march?armv7ve+$(FPARCH))
-
-MULTILIB_MATCHES     += $(foreach ARCH, $(all_v7_a_r), \
-			  march?armv7+fp=march?$(ARCH) \
-			  march?armv7+fp=march?$(ARCH)+fp)
-
-MULTILIB_MATCHES     += $(foreach ARCH, $(all_v8_archs), \
-			  march?armv7+fp=march?$(ARCH) \
-			  $(foreach FPARCH, $(v8_fps), \
-			    march?armv7+fp=march?$(ARCH)+$(FPARCH)))
-
-MULTILIB_MATCHES     += $(foreach ARCH, armv7e-m armv8-m.mainline, \
-			  march?armv7+fp=march?$(ARCH)+fp.dp)
-
-# PART 4 - Reuse rules
-
-MULTILIB_REUSE	     += mthumb=mthumb/mfpu.auto
-MULTILIB_REUSE	     += mthumb=mthumb/mfpu.auto/march.armv5te+fp
-MULTILIB_REUSE	     += mthumb=mthumb/march.armv5te+fp
-MULTILIB_REUSE	     += marm/mfpu.auto/march.armv5te+fp/mfloat-abi.hard=marm/march.armv5te+fp/mfloat-abi.hard
-MULTILIB_REUSE	     += marm/mfpu.auto/march.armv5te+fp/mfloat-abi.hard=march.armv5te+fp/mfloat-abi.hard
-MULTILIB_REUSE	     += marm/mfpu.auto/march.armv5te+fp/mfloat-abi.hard=mfpu.auto/march.armv5te+fp/mfloat-abi.hard
-MULTILIB_REUSE	     += mthumb/mfpu.auto/march.armv7+fp/mfloat-abi.hard=mthumb/march.armv7+fp/mfloat-abi.hard
-MULTILIB_REUSE	     += mthumb/mfpu.auto/march.armv7+fp/mfloat-abi.hard=mfpu.auto/march.armv7+fp/mfloat-abi.hard
-MULTILIB_REUSE	     += mthumb/mfpu.auto/march.armv7+fp/mfloat-abi.hard=march.armv7+fp/mfloat-abi.hard
+  
