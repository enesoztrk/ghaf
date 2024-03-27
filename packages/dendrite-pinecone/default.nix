{pkgs, ...}:

with pkgs;


buildGo119Module rec {
    pname = "dendrite-pinecone";
    version = "0.9.1";

     src = pkgs.fetchFromGitHub {
        owner = "tiiuae";
        repo = "dendrite";
        rev = "v0.9.1";
        sha256 = "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
      };
            subPackages = ["cmd/dendrite-demo-pinecone"];
         # patches = [./turnserver-crendentials-flags.patch];

    vendorHash = "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
}