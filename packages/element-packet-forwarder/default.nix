
{ pkgs ,
...
}:
let
  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable.latest.minimal;
    rustc = pkgs.rust-bin.stable.latest.minimal;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "element-packet-forwarder";
  version = "0.1.0";


  src = pkgs.fetchFromGitHub {
    owner = "tiiuae";
    repo = "element-packet-forwarder";
    rev = "feature/udp_voice_video_chat";
    sha256 = "1d5sjbsgxwpg5vz2s5apbaq1xzi95df0i9gkljdym1ggxld35jwa";
  };
 
  cargoHash = "sha256-8TdBCK3IevR6mmVOgLXg8FKAGhRLLFJ5a1uW72bw5Mo=";#pkgs.lib.fakeHash;

  buildPhase = ''
  cargo build --release
  '';
  checkPhase = ''
  cargo test
  '';

  installPhase = ''
  install -Dm777 target/release/element-packet-forwarder $out/bin/element-packet-forwarder
  '';


  meta = with pkgs.lib; {
    description = "Packet forwarder app to run element app on ghaf project";
    license = licenses.asl20;
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
