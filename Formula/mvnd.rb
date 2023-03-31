class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "1.0-m6-m39"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0-m6/maven-mvnd-1.0-m6-m39-darwin-amd64.zip"
      sha256 "70d7970bb077e72a6795fc432880bb4f52959288eb06724cdbaf97bf6b2d0854"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0-m6/maven-mvnd-1.0-m6-m39-darwin-aarch64.zip"
      sha256 "293342a932c43f27d200d51f899a2c0475167d925ea5d72e86ab9582b4d83ff2"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/1.0-m6/maven-mvnd-1.0-m6-m39-linux-amd64.zip"
    sha256 "61ea648ca626e56f15bad6ae7b6b373e929ae310d22cede53ce8f6b4ff429fbd"
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
