class FernApi < Formula
  desc "Stripe-level SDKs and Docs for your API"
  homepage "https://buildwithfern.com/"
  url "https://registry.npmjs.org/fern-api/-/fern-api-0.41.2.tgz"
  sha256 "5ce3139a345a291c5d3b3292b6a5228cd6f4936c18a1868ef996351d05375733"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "8d871f32589b22bab4e4897fb1cd204dee5769d59e3abb6183b815bb7124fc9b"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    output = shell_output("#{bin}/fern init 2>&1", 1)
    assert_match "Login required", output

    system bin/"fern", "--version"
  end
end
