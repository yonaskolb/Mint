class Mint < Formula
  desc "Dependency manager that installs and runs Swift command line tool packages"
  homepage "https://github.com/yonaskolb/Mint"
  url "https://github.com/yonaskolb/Mint/archive/0.6.0.tar.gz"
  sha256 "33bd9972ae4efc7aedfda43e740db9c1690caf51c33b89325307a1c2afba4cb9"
  head "https://github.com/yonaskolb/Mint.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
