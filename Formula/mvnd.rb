class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "0.9.0"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/0.8.2/maven-mvnd-0.8.2-darwin-amd64.zip"
      sha256 "87b430637038e0700af3e1a22bc4a05594d18e5e3624f1700de7f5e8fd629ce6"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/0.8.2/maven-mvnd-0.8.2-darwin-aarch64.zip"
      sha256 "48c0bcb1f44ed416c7c42bec6d19c8df2ef8af539a67b5b3f40f8d1e030b8c07"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/0.9.0/maven-mvnd-0.9.0-linux-amd64.zip"
    sha256 "5d33a9a5964905381df1e132a1a4c0cc6e4b7c72f75daa2d799181b68091fe9f"
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
