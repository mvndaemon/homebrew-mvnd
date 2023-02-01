class Mvnd < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "0.9.0"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/0.9.0/maven-mvnd-0.9.0-darwin-amd64.zip"
      sha256 "4a8b22eb37c528aa7fecf20b37e6d1975fa107aa2f4cc375ea071048910a83d7"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/0.9.0/maven-mvnd-0.9.0-darwin-aarch64.zip"
      sha256 "754bf38de73f79a478f5a39fb7cbec1cb9765eedbd0c6f6171197a10b48cb09c"
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
