{pkgs, ...}:

with pkgs;


buildGo119Module rec {
    pname = "dendrite-ghaf";
    version = "0.9.1";

     src = final.pkgs.fetchFromGitHub {
        owner = "matrix-org";
        repo = "dendrite";
        rev = "v0.9.1";
        sha256 = "sha256-Fg7yfP5cM/mNAsIZAI/WGNLuz8l3vxyY8bb1NjuZELc=";
      };
            subPackages = ["cmd/dendrite-demo-pinecone"];

    vendorSha256 = "sha256-+9mjg8avOHPQTzBnfgim10Lfgpsu8nTQf1qYB0SLFys=";
}
