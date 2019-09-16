# You probably want to install this with something like:
#
# `nix-env -f 'https://github.com/virusdave/nixpkgs/tarball/master' -iA '(import comby.nix) pkgs' `
#
# or similar...
{ stdenv, fetchurl, pcre, pkgconfig, autoPatchelfHook /*, fixDarwinDylibNames*/
, ...
}:

let
  platform_specifics = if (stdenv.isDarwin) then {
    platform = "macos";
    sha256 = "0542jv54ia1zlhxhb0lcnifvkiw75xhi43jp0ijl7xybf59zs2cv";
  } else {
    platform = "linux";
    sha256 = "0gr5n0r1rri39xmivp19pi9msy1vv2pd83jwckwzjzx3p6r27a7h";
  };
  sha256 = platform_specifics.sha256;
  platform = platform_specifics.platform;
in

with stdenv;
stdenv.mkDerivation rec {
  pname = "comby";
  version = "0.8.0";

  src = fetchurl {
    url = "https://github.com/comby-tools/comby/releases/download/${version}/comby-${version}-x86_64-${platform}.tar.gz";
    sha256 = sha256;
  };

  # The tarball is just the prebuilt binary, in the archive root.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = 
    lib.optionals (!stdenv.isDarwin) [autoPatchelfHook] ++
    lib.optionals stdenv.isDarwin [/*fixDarwinDylibNames*/];
  BuildInputs = [ pcre.out pkgconfig ];

  binary = "comby-${version}-x86_64-${platform}";
  binary_out = "comby";
  installPhase = ''
    #echo INSTALLING.
    mkdir -p $out/bin
    mkdir -p $out/lib
    cp -r ${pcre.out}/lib/* $out/lib
    mv ${binary} $out/bin/${binary_out}
    #ls -la $out/bin
    #echo INSTALLING DONE.
  '';

  # Comby binary has libpcre location hardcoded.  Yuck.
  # Fix that by pointing it to the pcre dependency.
  postFixup = stdenv.lib.optionalString stdenv.isDarwin ''
    for f in $out/lib/*.dylib; do
          install_name_tool -id $out/lib/$(basename $f) $f || true
    done
    /Applications/Xcode.app/Contents//Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool -change /usr/local/opt/pcre/lib/libpcre.1.dylib $out/lib/libpcre.1.dylib $out/bin/${binary_out}
  '';

  meta = with lib; {
    description = "A tool for changing code across many languages";
    homepage = https://comby.dev/;
    license = licenses.gpl;
    maintainers = [ maintainers.virusdave ];
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
  };
}
