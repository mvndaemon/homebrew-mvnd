class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "2.0.0-rc-1"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/2.0.0-rc-1/maven-mvnd-2.0.0-rc-1-darwin-amd64.zip"
      sha256 "76dd62a732ec085e23241aa38055803b7feec451576453b7737f01efc605e5c4"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/2.0.0-rc-1/maven-mvnd-2.0.0-rc-1-darwin-aarch64.zip"
      sha256 "a5f3474704fbcfa9038fd7efc6238551559e508df3cd143cfdb7278aecb1da6b"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/2.0.0-rc-1/maven-mvnd-2.0.0-rc-1-linux-amd64.zip"
    sha256 "58747368c166d13d9dda732614253944895b40e46a9c90c6193068f36015c110"
  end

  livecheck do
    url :stable
  end

  depends_on "openjdk" => :recommended

  def install
    # Remove windows files
    rm_f Dir["bin/*.cmd"]

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
