class MvndAT1 < Formula
  desc "Maven Daemon"
  homepage "https://github.com/mvndaemon/mvnd"
  license "Apache-2.0"
  version "1.0.1"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0.1/maven-mvnd-1.0.1-darwin-amd64.zip"
      sha256 "db352cd1e1eae7304546a6acc13a16f8590a43190701a581a640f877e6517815"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0.1/maven-mvnd-1.0.1-darwin-aarch64.zip"
      sha256 "feece7512f7c65c20eb801ace9de20f887dc09c145c64334aac69592f51786b1"
    end
  end
  on_linux do
    url "https://downloads.apache.org/maven/mvnd/1.0.1/maven-mvnd-1.0.1-linux-amd64.zip"
    sha256 "8c0c5b280f1d0f8c54a4e2126c92f52e66688bddfdb49c70735759f21a966051"
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
