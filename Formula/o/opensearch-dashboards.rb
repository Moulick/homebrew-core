class OpensearchDashboards < Formula
  desc "Open source visualization dashboards for OpenSearch"
  homepage "https://opensearch.org/docs/dashboards/index/"
  url "https://github.com/opensearch-project/OpenSearch-Dashboards.git",
      tag:      "3.0.0",
      revision: "c378e1f95a58498ad41c4c99f39e2072b2629085"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  no_autobump! because: :requires_manual_review

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "876fbfe98451b347628282dec9ba9367d99882e57cb430f3b2a86cdf5ad33928"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "876fbfe98451b347628282dec9ba9367d99882e57cb430f3b2a86cdf5ad33928"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "876fbfe98451b347628282dec9ba9367d99882e57cb430f3b2a86cdf5ad33928"
    sha256 cellar: :any_skip_relocation, sonoma:        "27e0f5bd26347b34a44324d9f035b60c5ada940e4f65ecd8cd39269d266fc5eb"
    sha256 cellar: :any_skip_relocation, ventura:       "27e0f5bd26347b34a44324d9f035b60c5ada940e4f65ecd8cd39269d266fc5eb"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "438ea67e9fad0910fa64b1063a167c1633395fa1d563aa829cd9ee2a549dc67b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "fd97261527b6b511eb78eb5f79e796d282c1acc182a6beeac6671436e871d26c"
  end

  depends_on "yarn" => :build
  depends_on "opensearch" => :test
  depends_on "node@20"

  # - Do not download node and discard all actions related to this node
  patch :DATA

  def install
    system "yarn", "osd", "bootstrap"
    system "node", "scripts/build", "--release", "--skip-os-packages", "--skip-archives", "--skip-node-download"

    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    cd "build/opensearch-dashboards-#{version}-#{os}-#{arch}" do
      inreplace "bin/use_node",
                /NODE=".+"/,
                "NODE=\"#{Formula["node@20"].opt_bin/"node"}\""

      inreplace "config/opensearch_dashboards.yml",
                /#\s*pid\.file: .+$/,
                "pid.file: #{var}/run/opensearchDashboards.pid"

      (etc/"opensearch-dashboards").install Dir["config/*"]
      rm_r(Dir["{config,data,plugins}"])

      prefix.install Dir["*"]
    end
  end

  def post_install
    (var/"log/opensearch-dashboards").mkpath

    (var/"lib/opensearch-dashboards").mkpath
    ln_s var/"lib/opensearch-dashboards", prefix/"data" unless (prefix/"data").exist?

    (var/"opensearch-dashboards/plugins").mkpath
    ln_s var/"opensearch-dashboards/plugins", prefix/"plugins" unless (prefix/"plugins").exist?

    ln_s etc/"opensearch-dashboards", prefix/"config" unless (prefix/"config").exist?
  end

  def caveats
    <<~EOS
      Data:    #{var}/lib/opensearch-dashboards/
      Logs:    #{var}/log/opensearch-dashboards/opensearch-dashboards.log
      Plugins: #{var}/opensearch-dashboards/plugins/
      Config:  #{etc}/opensearch-dashboards/
    EOS
  end

  service do
    run opt_bin/"opensearch-dashboards"
    log_path var/"log/opensearch-dashboards.log"
    error_log_path var/"log/opensearch-dashboards.log"
  end

  test do
    ENV["BABEL_CACHE_PATH"] = testpath/".babelcache.json"

    os_port = free_port
    (testpath/"data").mkdir
    (testpath/"logs").mkdir
    fork do
      exec Formula["opensearch"].bin/"opensearch", "-Ehttp.port=#{os_port}",
                                                   "-Epath.data=#{testpath}/data",
                                                   "-Epath.logs=#{testpath}/logs"
    end

    (testpath/"config.yml").write <<~YAML
      server.host: "127.0.0.1"
      path.data: #{testpath}/data
      opensearch.hosts: ["http://127.0.0.1:#{os_port}"]
    YAML

    osd_port = free_port
    fork { exec bin/"opensearch-dashboards", "-p", osd_port.to_s, "-c", testpath/"config.yml" }

    output = nil

    max_attempts = 100
    attempt = 0

    loop do
      attempt += 1
      break if attempt > max_attempts

      sleep 3

      output = Utils.popen_read("curl", "--location", "--silent", "127.0.0.1:#{osd_port}")
      break if output.present? && output != "OpenSearch Dashboards server is not ready yet"
    end

    assert_includes output, "<title>OpenSearch Dashboards</title>"
  end
end

__END__
diff --git a/src/dev/build/build_distributables.ts b/src/dev/build/build_distributables.ts
index d764c5df28..e37b71e04a 100644
--- a/src/dev/build/build_distributables.ts
+++ b/src/dev/build/build_distributables.ts
@@ -63,8 +63,6 @@ export async function buildDistributables(log: ToolingLog, options: BuildOptions
    */
   await run(Tasks.VerifyEnv);
   await run(Tasks.Clean);
-  await run(options.downloadFreshNode ? Tasks.DownloadNodeBuilds : Tasks.VerifyExistingNodeBuilds);
-  await run(Tasks.ExtractNodeBuilds);

   /**
    * run platform-generic build tasks
diff --git a/src/dev/build/tasks/create_archives_sources_task.ts b/src/dev/build/tasks/create_archives_sources_task.ts
index 5ba01ad129..b4ecbb0d3d 100644
--- a/src/dev/build/tasks/create_archives_sources_task.ts
+++ b/src/dev/build/tasks/create_archives_sources_task.ts
@@ -41,38 +41,6 @@ export const CreateArchivesSources: Task = {
           source: build.resolvePath(),
           destination: build.resolvePathForPlatform(platform),
         });
-
-        log.debug(
-          'Generic build source copied into',
-          platform.getNodeArch(),
-          'specific build directory'
-        );
-
-        // copy node.js install
-        await scanCopy({
-          source: (await getNodeDownloadInfo(config, platform)).extractDir,
-          destination: build.resolvePathForPlatform(platform, 'node'),
-        });
-
-        // ToDo [NODE14]: Remove this Node.js 14 fallback download
-        // Copy the Node.js 14 binaries into node/fallback to be used by `use_node`
-        if (platform.getBuildName() === 'darwin-arm64') {
-          log.warning(`There are no fallback Node.js versions released for darwin-arm64.`);
-        } else {
-          await scanCopy({
-            source: (
-              await getNodeVersionDownloadInfo(
-                NODE14_FALLBACK_VERSION,
-                platform.getNodeArch(),
-                platform.isWindows(),
-                config.resolveFromRepo()
-              )
-            ).extractDir,
-            destination: build.resolvePathForPlatform(platform, 'node', 'fallback'),
-          });
-        }
-
-        log.debug('Node.js copied into', platform.getNodeArch(), 'specific build directory');
       })
     );
   },
diff --git a/src/dev/notice/generate_build_notice_text.js b/src/dev/notice/generate_build_notice_text.js
index b32e200915..2aab53f3ea 100644
--- a/src/dev/notice/generate_build_notice_text.js
+++ b/src/dev/notice/generate_build_notice_text.js
@@ -48,7 +48,7 @@ export async function generateBuildNoticeText(options = {}) {

   const packageNotices = await Promise.all(packages.map(generatePackageNoticeText));

-  return [noticeFromSource, ...packageNotices, generateNodeNoticeText(nodeDir, nodeVersion)].join(
+  return [noticeFromSource, ...packageNotices, ''].join(
     '\n---\n'
   );
 }
