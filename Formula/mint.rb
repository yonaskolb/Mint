class Mint < Formula
  desc "Dependency manager that installs and runs Swift command line tool packages"
  homepage "https://github.com/yonaskolb/Mint"
  url "https://github.com/yonaskolb/Mint/archive/0.1.0.tar.gz"
  sha256 "52ca8deb5e3648841210e5267b5f549107c326087c99a110b2b4c85145c06c3f"
  head "https://github.com/yonaskolb/Mint.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
