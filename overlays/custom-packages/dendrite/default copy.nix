(final: prev: {
   dendrite = (prev.dendrite.override {
        buildGoModule = final.pkgs.buildGo119Module;
      }).overrideAttrs (_: 
    let
      dendriteVersion = "0.9.1";
      my_src = final.pkgs.fetchFromGitHub {
        owner = "matrix-org";
        repo = "dendrite";
        rev = "v0.9.1";
        sha256 = "sha256-Fg7yfP5cM/mNAsIZAI/WGNLuz8l3vxyY8bb1NjuZELc=";
      };
    in  {
      buildGoModule = prev.pkgs.buildGo119Module rec {
            subPackages = ["cmd/dendrite-demo-pinecone"];

        pname = "dendrite";
        version = dendriteVersion;
        src = my_src;
        vendorHash = "sha256-+9mjg8avOHPQTzBnfgim10Lfgpsu8nTQf1qYB0SLFys=";
      };
    }
  );
})
