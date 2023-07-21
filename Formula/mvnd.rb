class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "1.0-m7-m39"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0-m7/maven-mvnd-1.0-m7-m39-darwin-amd64.zip"
      sha256 "a396b431355123583824fde79aaad37e9fde688ebac51e1e85811b39ae8199ca"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0-m7/maven-mvnd-1.0-m7-m39-darwin-aarch64.zip"
      sha256 "9298dd0b89eba5273347a5a7eba257b79e62edfcf8a433f67891c21eb74022f6"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/1.0-m7/maven-mvnd-1.0-m7-m39-linux-amd64.zip"
    sha256 "2f2ca40f5451f89de1ccd798ad8c966a77196622c95f0387f9a00f91bb55b6a2"
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
