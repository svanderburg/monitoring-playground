{pkgs, ...}:

{
  dysnomia.enableLegacyModules = false;

  services = {
    disnix = {
      enable = true;
      enableProfilePath = true;
    };

    openssh = {
      enable = true;
    };
  };

  networking.firewall.enable = false;

  virtualisation.memorySize = 8192;
  virtualisation.diskSize = 10240;

  environment = {
    systemPackages = [
      pkgs.mc
    ];
  };
}
