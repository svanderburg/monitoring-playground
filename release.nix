{ nixpkgs ? <nixpkgs>
, monitoring-playground ? {outPath = ./.; rev = 1234;}
, officialRelease ? false
, systems ? [ "i686-linux" "x86_64-linux" ]
, nix-processmgmt ? { outPath = ../nix-processmgmt; rev = 1234; }
}:

let
  pkgs = import nixpkgs {};

  disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
    inherit nixpkgs;
  };

  version = builtins.readFile ./version;
in
rec {
  tarball = disnixos.sourceTarball {
    name = "monitoring-playground-tarball";
    src = monitoring-playground;
    inherit officialRelease version;
  };

  build = pkgs.lib.genAttrs systems (system:
    let
      pkgs = import nixpkgs { inherit system; };

      disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
        inherit nixpkgs system;
      };
      in
      disnixos.buildManifest {
        name = "monitoring-playground";
        inherit tarball version;
        servicesFile = "deployment/DistributedDeployment/services.nix";
        networkFile = "deployment/DistributedDeployment/network-qemu.nix";
        distributionFile = "deployment/DistributedDeployment/distribution-minimal.nix";
        extraParams = {
          inherit nix-processmgmt;
          useStreamTasks = true;
        };
      }
    );

  tests = disnixos.disnixTest rec {
    name = "monitoring-playground-tests";
    inherit tarball;
    manifest = builtins.getAttr (builtins.currentSystem) build;
    networkFile = "deployment/DistributedDeployment/network-qemu.nix";
    testScript = ''
      test2.succeed("sleep 10")
      test2.succeed("test-cpu-alerts")
      test2.succeed("test-mem-alerts")
    '';
  };
}
