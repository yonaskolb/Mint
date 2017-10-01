class Mint < Formula
  desc "Dependency manager that installs and runs Swift command line tool packages"
  homepage "https://github.com/yonaskolb/Mint"
  url "https://github.com/yonaskolb/Mint/archive/0.4.0.tar.gz"
  sha256 "8ca53fedbe080d79b95a5fbec9fe4350dc58b9a6e89f8c80dfbd6d638a01f700"
  head "https://github.com/yonaskolb/Mint.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
