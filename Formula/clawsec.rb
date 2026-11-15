class Clawsec < Formula
  desc "Encrypted netcat: password-authenticated tunnels, file transfer, SOCKS5, VPN"
  homepage "https://github.com/LF3551/ClawSec"
  url "https://github.com/LF3551/ClawSec/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "3d9ad6e2cb41f67c0c28305babf33469f69b369bfff460251d8e189c4f5e76c1"
  license "BSD-3-Clause"
  head "https://github.com/LF3551/ClawSec.git", branch: "main"

  depends_on "argon2"
  depends_on "openssl@3"

  uses_from_macos "zlib"

  def install
    openssl = Formula["openssl@3"]
    argon2 = Formula["argon2"]
    cxx_runtime = OS.mac? ? "-lc++" : "-lstdc++"
    system "make", "-C", "src", "generic",
           "XFLAGS=-I#{openssl.opt_include} -I#{argon2.opt_include}",
           "XLIBS=-L#{openssl.opt_lib} -L#{argon2.opt_lib} " \
           "-lssl -lcrypto -largon2 -lz #{cxx_runtime}"
    bin.install "src/clawsec"
    man1.install "docs/clawsec.1"
    bash_completion.install "completions/clawsec.bash" => "clawsec"
    zsh_completion.install "completions/_clawsec"
    fish_completion.install "completions/clawsec.fish"
  end

  test do
    assert_match "ClawSec #{version}", shell_output("#{bin}/clawsec --version")

    # Encrypted file transfer over localhost: --recv server, --send client
    port = free_port
    password = "brew-test-password-1234"
    (testpath/"inbox").mkpath
    (testpath/"payload.bin").write("ClawSec Homebrew test\n" * 1000)
    server = spawn bin/"clawsec", "-l", "-p", port.to_s, "-k", password,
                   "--recv", (testpath/"inbox").to_s, [:out, :err] => File::NULL
    sleep 2
    output = shell_output("#{bin}/clawsec -k #{password} --send #{testpath}/payload.bin " \
                          "127.0.0.1 #{port} 2>&1")
    assert_match "SHA-256 verified", output
    Process.wait(server)
    assert_equal (testpath/"payload.bin").read, (testpath/"inbox/payload.bin").read
  end
end
