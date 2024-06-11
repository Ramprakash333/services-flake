{ pkgs, lib, name, config, ... }:

let
  inherit (lib) types;
in
{
  options = {
    enable = lib.mkEnableOption name;

    package = lib.mkPackageOption pkgs "mongodb" {};
    
    dataDir = lib.mkOption {
      type = types.str;
      default = "./data/${name}";
      description = "The mongodb data directory";
    };

    additionalArgs = lib.mkOption {
      type = types.listOf types.lines;
      default = [ "--noauth" ];
      example = [ "--port" "27017" "--noauth" ];
      description = ''
        Additional arguments passed to `mongod`.
      '';
    };

    initDatabaseUsername = lib.mkOption {
      type = types.str;
      default = "";
      example = "mongoadmin";
      description = ''
        This used in conjunction with initDatabasePassword, create a new user and set that user's password. This user is created in the admin authentication database and given the role of root, which is a "superuser" role.
      '';
    };

    initDatabasePassword = lib.mkOption {
      type = types.str;
      default = "";
      example = "secret";
      description = ''
        This used in conjunction with initDatabaseUsername, create a new user and set that user's password. This user is created in the admin authentication database and given the role of root, which is a "superuser" role.
      '';
    };
    outputs.settings = lib.mkOption {
        type = types.deferredModule;
        internal = true;
        readOnly = true;
        default = {
        processes = {
                "${name}" =
                let
                    setupScript = pkgs.writeShellApplication  {
                        name = "setup-mongodb";
                        runtimeInputs = [ pkgs.coreutils ];
                        text = ''
                            set -euo pipefail

                            export MONGODBDATA=${config.dataDir}

                            if [[ ! -d "$MONGODBDATA" ]]; then
                                mkdir -p "$MONGODBDATA"
                            fi
                        '';
                    };

                    startScript = pkgs.writeShellApplication {
                        name = "start-mongodb";
                        runtimeInputs = [ pkgs.coreutils config.package ];
                        text = ''
                            set -euo pipefail
                            ${setupScript}
                            exec mongod ${
                            lib.concatStringsSep " " config.additionalArgs
                            } -dbpath "$MONGODBDATA"
                        '';
                    };
                in
                    {
                        command = startScript;
                        namespace = name;
                    };
                };
            };
        };
    };
}