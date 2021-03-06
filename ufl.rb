require 'formula'

class Ufl < Formula
  homepage 'https://bitbucket.org/fenics-project/ufl'
  url 'https://bitbucket.org/fenics-project/ufl/downloads/ufl-1.5.0.tar.gz'
  sha1 'ddd7d2ad61af9774f2854a4ca729cce6178140a8'

  depends_on :python
  depends_on 'numpy' => :python

  def install
    ENV.deparallelize

    system 'python', 'setup.py', 'install', "--prefix=#{prefix}"
  end
end
