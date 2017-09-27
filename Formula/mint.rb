class Mint < Formula
  desc "Dependency manager that installs and runs Swift command line tool packages"
  homepage "https://github.com/yonaskolb/Mint"
  url "https://github.com/yonaskolb/Mint/archive/0.2.0.tar.gz"
  sha256 "c0b1e000593a6f323307b9fafa6e38b1e54c7f5bf2ed0687317d8c6f9ec1f16c"
  head "https://github.com/yonaskolb/Mint.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
