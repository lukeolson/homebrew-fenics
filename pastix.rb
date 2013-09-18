require 'formula'

class Pastix < Formula
  homepage 'http://pastix.gforge.inria.fr'
  #url 'https://gforge.inria.fr/frs/download.php/32044/pastix_release_4030.tar.bz2'
  #sha1 'e43b06b27d1f600abb9fdcaee9c956a3f3976514'
  #version '5.2.1r4030'
  url 'svn://scm.gforge.inria.fr/svnroot/ricar/tags/5.2.1'
  version '5.2.1'

  depends_on 'metis4'   => :optional     # Use METIS instead of Scotch.
  depends_on 'scotch5'  => :optional     # Scotch v5.*
  depends_on 'scotch'   => :recommended  # Scotch v6.*
  depends_on 'openblas' => :optional     # Use Accelerate by default.
  depends_on 'open-mpi' => 'enable-mpi-thread-multiple'
  depends_on :mpi       => [:cc, :f90]
  depends_on :fortran

  def patches
    { :p1 => 'https://gist.github.com/anonymous/6582233/raw/5000062b8e9434ec042bef3290de05a49767f7fe/patch1' }
  end

  def install

    if build.with? 'scotch'
      scotch = 'scotch'
    else
      scotch = 'scotch5'
    end

    cp 'config/MAC.in', 'config.in'
    inreplace 'config.in' do |s|
      s.change_make_var! "CCPROG", ENV.cc
      s.change_make_var! "CFPROG", ENV.fc
      s.change_make_var! "CF90PROG", ENV.fc
      s.change_make_var! "EXTRALIB", "-L#{Formula.factory('gfortran').opt_prefix}/gfortran/lib -lgfortran -lm"

      s.gsub! /#\s*ROOT\s*=/, "ROOT = "
      s.change_make_var! "ROOT", prefix
      s.gsub! /#\s*INCLUDEDIR\s*=/, "INCLUDEDIR = "
      s.change_make_var! "INCLUDEDIR", include
      s.gsub! /#\s*LIBDIR\s*=/, "LIBDIR = "
      s.change_make_var! "LIBDIR", lib
      s.gsub! /#\s*BINDIR\s*=/, "BINDIR = "
      s.change_make_var! "BINDIR", bin

      s.gsub! /#\s*SHARED\s*=/, "SHARED = "
      s.change_make_var! "SHARED", 1
      s.gsub! /#\s*SOEXT\s*=/, "SOEXT = "
      s.gsub! /#\s*SHARED_FLAGS\s*=/, "SHARED_FLAGS = "
      #s.change_make_var! "SHARED_FLAGS", "-shared"

      s.gsub! /#\s*CCFDEB\s*:=/, "CCFDEB := "
      s.gsub! /#\s*CCFOPT\s*:=/, "CCFOPT := "
      s.gsub! /#\s*CFPROG\s*:=/, "CFPROG := "

      s.gsub! /#\s*VERSIONINT\s+=\s+_int32/, "VERSIONINT = _int32"
      s.gsub! /#\s*CCTYPES\s+=\s+\-DINTSIZE32/, "CCTYPES = -DINTSIZE32"

      s.gsub! /SCOTCH_HOME\s*\?=/, "SCOTCH_HOME="
      # s.change_make_var! "SCOTCH_HOME", Formula.factory('scotch5').prefix
      # s.change_make_var! "SCOTCH_HOME", Formula.factory('scotch').prefix
      s.change_make_var! "SCOTCH_HOME", Formula.factory(scotch).prefix

      if build.with? 'metis4'
        s.gsub! /#\s*VERSIONORD\s*=\s*_metis/, "VERSIONORD = _metis"
        s.gsub! /#\s*METIS_HOME/, "METIS_HOME"
        s.change_make_var! "METIS_HOME", Formula.factory('metis4').prefix
        s.gsub! /#\s*CCPASTIX\s*:=\s*\$\(CCPASTIX\)\s+-DMETIS\s+-I\$\(METIS_HOME\)\/Lib/, "CCPASTIX := \$(CCPASTIX) -DMETIS -I#{Formula.factory('metis4').include}"
        s.gsub! /#\s*EXTRALIB\s*:=\s*\$\(EXTRALIB\)\s+-L\$\(METIS_HOME\)\s+-lmetis/, "EXTRALIB := \$\(EXTRALIB\) -L#{Formula.factory('metis4').lib} -lmetis"
      end

      if build.with? 'openblas'
        s.gsub! /#\s*BLAS_HOME\s*=\s*\/path\/to\/blas/, "BLAS_HOME = #{Formula.factory('openblas').lib}"
        s.change_make_var! "BLASLIB", "-lopenblas"
      end
    end
    system "make"
    system "make install"
    system "make examples"
    system "./example/bin/simple -lap 100"
    prefix.install 'config.in'    # For the record.
    share.install Dir['example']  # Contains all test programs.
    ohai 'Simple test result is in ~/Library/Logs/Homebrew/pastix. Please check them.'
  end

  def test
    Dir.foreach("#{share}/example/bin") do |example|
      next if example =~ /^\./ or example =~ /plot_memory_usage/
      # The following tests currently crash.
      next if example == 'fsimple' or example == 'isolate_zeros' or example == 'reentrant' or example == 'murge-product'
      if example =~ /murge/
        system "#{share}/example/bin/#{example} 100 100"
      else
        system "#{share}/example/bin/#{example} -lap 100"  # 100x100 Laplacian.
      end
    end
    ohai 'All test output is in ~/Library/Logs/Homebrew/pastix. Please check.'
  end
end