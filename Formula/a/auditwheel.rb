class Auditwheel < Formula
  include Language::Python::Virtualenv

  desc "Auditing and relabeling cross-distribution Linux wheels"
  homepage "https://github.com/pypa/auditwheel"
  url "https://files.pythonhosted.org/packages/e4/6a/9582a6a14bdde843f57ef34a4a92197e80fd3a1dab64f8d3c10f96fa9fb4/auditwheel-6.3.0.tar.gz"
  sha256 "05c70a234fa14c140aa6d9076135d9550962d95849911b8d5d0419a3add09f00"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ed7e4d6d91cd9ac6d655127ccaf2619d493aedbeed65cfea6801dfb736d0144c"
  end

  depends_on :linux
  depends_on "python@3.13"

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/d0/63/68dbb6eb2de9cb10ee4c9c14a0148804425e13c4fb20d61cce69f53106da/packaging-24.2.tar.gz"
    sha256 "c228a6dc5e932d346bc5739379109d49e8853dd8223571c7c5b55260edc0b97f"
  end

  resource "pyelftools" do
    url "https://files.pythonhosted.org/packages/b9/ab/33968940b2deb3d92f5b146bc6d4009a5f95d1d06c148ea2f9ee965071af/pyelftools-0.32.tar.gz"
    sha256 "6de90ee7b8263e740c8715a925382d4099b354f29ac48ea40d840cf7aa14ace5"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/auditwheel -V")

    resource "homebrew-test-wheel" do
      url "https://files.pythonhosted.org/packages/4c/00/e17e2a8df0ff5aca2edd9eeebd93e095dd2515f2dd8d591d84a3233518f6/cffi-1.16.0-cp312-cp312-musllinux_1_1_x86_64.whl"
      sha256 "2d92b25dbf6cae33f65005baf472d2c245c050b1ce709cc4588cdcdd5495b520"
    end

    resource("homebrew-test-wheel").stage testpath

    output = shell_output("#{bin}/auditwheel show cffi-1.16.0-cp312-cp312-musllinux_1_1_x86_64.whl")
    assert_match "is consistent with\nthe following platform tag: \"linux_x86_64\"", output
  end
end
