{
  description = "cheatshh - Interactive CLI for managing command line cheatsheets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # homeManagerModules is system-agnostic, so it lives outside eachDefaultSystem
    # and is merged in with //.
    {
      homeManagerModules.cheatshh = import ./nix/hm-module.nix self;
      homeManagerModules.default  = import ./nix/hm-module.nix self;
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python3 = pkgs.python3;

        # Runtime tools the shell script (cheats.sh) calls directly
        runtimeDeps = [
          pkgs.jq          # JSON operations throughout cheats.sh
          pkgs.fzf          # Fuzzy-finder UI
          pkgs.newt         # Provides the `whiptail` dialog binary
          python3.pkgs.yq   # Provides `tomlq` for reading cheatshh.toml
        ];
      in
      {
        packages.default = python3.pkgs.buildPythonApplication {
          pname = "cheatshh";
          version = "1.1.1";
          src = ./.;
          pyproject = true;

          build-system = [ python3.pkgs.hatchling ];

          # main.py only uses stdlib; the pyproject.toml deps are either
          # satisfied by system tools above or unused at the Python level.
          dependencies = [ python3.pkgs.setuptools ];

          nativeBuildInputs = [
            pkgs.makeWrapper
            # Strips fuzzyfinder/fzf-bin/whiptail from the wheel's dependency
            # metadata so the runtime deps check doesn't reject the build.
            # Those are either system tools (fzf, whiptail) or unused by main.py.
            python3.pkgs.pythonRelaxDepsHook
          ];

          pythonRemoveDeps = [ "fuzzyfinder" "fzf-bin" "whiptail" ];

          postInstall = ''
            wrapProgram $out/bin/cheatshh \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
          '';

          meta = with pkgs.lib; {
            description = "Interactive CLI for managing command line cheatsheets";
            homepage = "https://github.com/AnirudhG07/cheatshh";
            license = licenses.asl20;
            mainProgram = "cheatshh";
            platforms = platforms.unix;
          };
        };

        # `nix run` support
        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        # `nix develop` shell for working on the project
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.uv
            (python3.withPackages (ps: [ ps.hatchling ps.setuptools ]))
          ] ++ runtimeDeps;
        };
      });
}
