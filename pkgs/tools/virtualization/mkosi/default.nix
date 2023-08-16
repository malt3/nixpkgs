{ lib
, pkgs
, fetchFromGitHub
, python3
, stdenv
}:
let
  systemd = pkgs.systemd.override {
    # Will be added in #243242
    # withRepart = true;
    withEfi = true;
    withUkify = true;
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "mkosi";
  version = "15.2-pre"; # 15.1 is the latest release, but we require a newer commit
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "systemd";
    repo = "mkosi";
    # Fix from the commit is needed to run on NixOS,
    # see https://github.com/systemd/mkosi/issues/1792
    rev = "ca9673cbcbd9f293e5566cec4a1ba14bbcd075b8";
    hash = "sha256-y5gG/g33HBpH1pTXfjHae25bc5p/BvlCm9QxOIYtcA8=";
  };

  # Fix ctypes finding library
  # https://github.com/NixOS/nixpkgs/issues/7307
  patchPhase = lib.optionalString stdenv.isLinux ''
    substituteInPlace mkosi/run.py --replace \
      'ctypes.util.find_library("c")' "'${stdenv.cc.libc}/lib/libc.so.6'"
  '';

  nativeBuildInputs = [
    python3.pkgs.setuptools
  ];


  propagatedBuildInputs = [
    systemd
    python3.pkgs.pexpect
    pkgs.bubblewrap
  ];

  postInstall = ''
    wrapProgram $out/bin/mkosi \
      --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  checkInputs = [
    python3.pkgs.pytestCheckHook
  ];

  meta = with lib; {
    description = "Build legacy-free OS images";
    homepage = "https://github.com/systemd/mkosi";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ malt3 katexochen ];
  };
}
