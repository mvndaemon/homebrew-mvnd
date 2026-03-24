class Mvnd < Formula
  desc "Apache Maven Daemon"
  homepage "https://github.com/apache/maven-mvnd"
  license "Apache-2.0"
  version "1.0.5"
  on_macos do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0.5/maven-mvnd-1.0.5-darwin-amd64.zip"
      sha256 "95e12908f24fd018ee41e5d31fe43a86340877e9b937651732e310b250411de3"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0.5/maven-mvnd-1.0.5-darwin-aarch64.zip"
      sha256 "bd98f847478de20158242f6cce6d9bc6cb6e3e9ba7b932237f0122f52a8de5a3"
    end
  end
  on_linux do
    on_intel do
      url "https://downloads.apache.org/maven/mvnd/1.0.5/maven-mvnd-1.0.5-linux-amd64.zip"
      sha256 "4a8d83bbf7757a1132c4116cfeea69aaa93b341b8253344ff42b33001f281830"
    end
    on_arm do
      url "https://downloads.apache.org/maven/mvnd/1.0.5/maven-mvnd-1.0.5-linux-aarch64.zip"
      sha256 "5f68558d8950d4020eecd19e10fae40a4fcb4db00ebd359dad39b4bb52b9efa0"
    end
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
