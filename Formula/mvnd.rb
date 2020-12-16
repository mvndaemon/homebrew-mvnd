class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  head "https://github.com/mvndaemon/mvnd.git"
  version "0.1.1"

  livecheck do
    url :stable
  end

  bottle :unneeded

  depends_on "openjdk"

  resource "mvndzip" do
    on_macos do
      url "https://github.com/mvndaemon/mvnd/releases/download/0.2.0/mvnd-0.2.0-darwin-amd64.zip"
      sha256 "a5b193dfc59393cb4b3c14021daf090f4f3c19355e70f065002346c20fdadb54"
    end

    on_linux do
      url "https://github.com/mvndaemon/mvnd/releases/download/0.2.0/mvnd-0.2.0-linux-amd64.zip"
      sha256 "5fc9e07ecbbbe17e7cea480b70d77a16530fba7c869f0e7bd2a0a718409e4b89"
    end
  end

  def install
    libexec.install resource("mvndzip")

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
