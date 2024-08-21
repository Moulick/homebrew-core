class Json2ts < Formula
  desc "Compile JSONSchema to TypeScript type declarations"
  homepage "https://github.com/bcherny/json-schema-to-typescript"
  url "https://registry.npmjs.org/json-schema-to-typescript/-/json-schema-to-typescript-15.0.1.tgz"
  sha256 "79a2c3e859ade86dc41f44c1b24be27a8ee83f06a20380122c14e3b2040fe0fc"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "7ed247ec8721d93165ab4b809c930e8b67127f09b860bd081ee870475c23ddc7"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "7ed247ec8721d93165ab4b809c930e8b67127f09b860bd081ee870475c23ddc7"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "7ed247ec8721d93165ab4b809c930e8b67127f09b860bd081ee870475c23ddc7"
    sha256 cellar: :any_skip_relocation, sonoma:         "1a6b22d3b49cf48d603acdbb92456974c08ba9eb43c3bf887f20bed888f8f49a"
    sha256 cellar: :any_skip_relocation, ventura:        "1a6b22d3b49cf48d603acdbb92456974c08ba9eb43c3bf887f20bed888f8f49a"
    sha256 cellar: :any_skip_relocation, monterey:       "1a6b22d3b49cf48d603acdbb92456974c08ba9eb43c3bf887f20bed888f8f49a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "d44b416cbfb6ead0f72287edf39d78e9dbf9e3429de82d1a399e31ef4b749572"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    schema = <<~JSON
      {
        "title": "Example Schema",
        "type": "object",
        "properties": {
          "firstName": {
            "type": "string"
          },
          "lastName": {
            "type": "string"
          },
          "age": {
            "description": "Age in years",
            "type": "integer",
            "minimum": 0
          },
          "hairColor": {
            "enum": ["black", "brown", "blue"],
            "type": "string"
          }
        },
        "additionalProperties": false,
        "required": ["firstName", "lastName"]
      }
    JSON

    typescript = <<~TS
      /* eslint-disable */
      /**
       * This file was automatically generated by json-schema-to-typescript.
       * DO NOT MODIFY IT BY HAND. Instead, modify the source JSONSchema file,
       * and run json-schema-to-typescript to regenerate this file.
       */

      export interface ExampleSchema {
        firstName: string;
        lastName: string;
        /**
         * Age in years
         */
        age?: number;
        hairColor?: "black" | "brown" | "blue";
      }
    TS

    output = pipe_output(bin/"json2ts", schema)
    assert_equal output, typescript
  end
end
