class Netpbm < Formula
  desc "Image manipulation"
  homepage "http://netpbm.sourceforge.net"
  # Maintainers: Look at https://sourceforge.net/p/netpbm/code/HEAD/tree/
  # for versions and matching revisions
  url "http://svn.code.sf.net/p/netpbm/code/advanced", :revision => 2294
  version "10.68"

  head "http://svn.code.sf.net/p/netpbm/code/trunk"

  bottle do
    cellar :any
    revision 2
    sha256 "ad369fbec6067be0355b02aa02f5b542224cbf9835974de7d0d36ea2a1966e2f" => :el_capitan
    sha256 "a3c04a8257065886cf7f19d246a586a011b8c7d8fd708e5e669b769340e007fa" => :yosemite
    sha256 "5d668e7795efa192da1bf14e1cfc27f458b58a40dfaa63873d7a642b5ec06a4f" => :mavericks
    sha256 "246ed13eeb79eaf97d4c4423c9971aa7cadf9a0badaf528c050d1ff8e8198d72" => :x86_64_linux
    sha256 "b0c160558d0f764360041069129877bfc7e6d9fc81b3dabfa6cf4fe9a9efc21b" => :mountain_lion
  end

  option :universal

  depends_on "libtiff"
  depends_on "jasper"
  depends_on "libpng"
  unless OS.mac?
    depends_on "flex"
    depends_on "zlib"
  end

  def install
    ENV.universal_binary if build.universal?

    cp "config.mk.in", "config.mk"

    inreplace "config.mk" do |s|
      s.remove_make_var! "CC"
      if OS.linux?
        s.change_make_var! "CFLAGS_SHLIB", "-fPIC"
      elsif OS.mac?
        s.change_make_var! "CFLAGS_SHLIB", "-fno-common"
        s.change_make_var! "NETPBMLIBTYPE", "dylib"
        s.change_make_var! "NETPBMLIBSUFFIX", "dylib"
        s.change_make_var! "LDSHLIB", "--shared -o $(SONAME)"
      end
      s.change_make_var! "TIFFLIB", "-ltiff"
      s.change_make_var! "JPEGLIB", "-ljpeg"
      s.change_make_var! "PNGLIB", "-lpng"
      s.change_make_var! "ZLIB", "-lz"
      s.change_make_var! "JASPERLIB", "-ljasper"
      s.change_make_var! "JASPERHDR_DIR", "#{Formula["jasper"].opt_include}/jasper"
    end

    ENV.deparallelize
    system "make"
    system "make", "package", "pkgdir=#{buildpath}/stage"

    cd "stage" do
      inreplace "pkgconfig_template" do |s|
        s.gsub! "@VERSION@", File.read("VERSION").sub("Netpbm ", "").chomp
        s.gsub! "@LINKDIR@", lib
        s.gsub! "@INCLUDEDIR@", include
      end

      prefix.install %w[bin include lib misc]
      # do man pages explicitly; otherwise a junk file is installed in man/web
      man1.install Dir["man/man1/*.1"]
      man5.install Dir["man/man5/*.5"]
      lib.install Dir["link/*.a"]
      (lib/"pkgconfig").install "pkgconfig_template" => "netpbm.pc"
    end

    (bin/"doc.url").unlink
  end

  test do
    fwrite = Utils.popen_read("#{bin}/pngtopam #{test_fixtures("test.png")} -alphapam")
    (testpath/"test.pam").write fwrite
    system "#{bin}/pamdice", "test.pam", "-outstem", testpath/"testing"
    assert File.exist?("testing_0_0.")
  end
end
