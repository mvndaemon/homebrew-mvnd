class Mvnd < Formula
  desc "Apache Maven Daemon"
  homepage "https://github.com/apache/maven-mvnd"
  license "Apache-2.0"
  version "1.0.6"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0.6/maven-mvnd-1.0.6-darwin-amd64.zip"
      sha256 "768fe975bf5dc306586b55887082859b56384e8c88372b63d52d9a9b7bd3bc87"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0.6/maven-mvnd-1.0.6-darwin-aarch64.zip"
      sha256 "33bb11304b048d5d4e33db501d36215cdf8fa1e77192eda7c000feb2d62d219e"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/2.0.0-rc-3/maven-mvnd-2.0.0-rc-3-linux-amd64.zip"
    sha256 "f770cf7122b54950a3173b0870f3c9f0706ad8899e2cfd5fce40774a421e9cd5"
  end

  livecheck do
    url :stable
  end

  depends_on "openjdk" => :recommended

  def install
    # Remove windows files
    rm_f Dir["bin/*.cmd"]

    bash_completion.install "bin/mvnd-bash-completion.bash"

    libexec.install Dir["*"]

    Pathname.glob("#{libexec}/bin/*") do |file|
      next if file.directory?

      basename = file.basename
      (bin/basename).write_env_script file, Language::Java.overridable_java_home_env
    end

    daemon = var + 'run/mvnd'
    FileUtils.mkdir_p "#{daemon}", mode: 0775 unless daemon.exist?
    FileUtils.ln_sf(daemon, libexec + 'daemon')
  end

  test do
    (testpath/"settings.xml").write <<~EOS
      <settings><localRepository>#{testpath}/repository</localRepository></settings>
    EOS
    (testpath/"pom.xml").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <project xmlns="https://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="https://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>org.homebrew</groupId>
        <artifactId>maven-test</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <properties>
         <maven.compiler.source>1.8</maven.compiler.source>
         <maven.compiler.target>1.8</maven.compiler.target>
        </properties>
      </project>
    EOS
    (testpath/"src/main/java/org/homebrew/MavenTest.java").write <<~EOS
      package org.homebrew;
      public class MavenTest {
        public static void main(String[] args) {
          System.out.println("Testing Maven with Homebrew!");
        }
      }
    EOS
    system "#{bin}/mvnd", "-gs", "#{testpath}/settings.xml", "compile"
  end
end
