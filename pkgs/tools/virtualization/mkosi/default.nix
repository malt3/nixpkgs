{
  lib,
  pkgs,
  fetchFromGitHub,
  python3,
  stdenv,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "mkosi";
  version = "15";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "systemd";
    repo = "mkosi";
    rev = "06eaadf1213763ecd6f9edc519fd4e2cd63d0966";
    hash = "sha256-iJ9o0AX3kfppT57yFJw7mUDPspgfQpWS9y9ayfu+wGk=";
  };

  # Fix ctypes finding library
  # https://github.com/NixOS/nixpkgs/issues/7307
  patchPhase = lib.optionalString stdenv.isLinux ''
    substituteInPlace mkosi/run.py --replace \
      'ctypes.util.find_library("c")' "'${stdenv.cc.libc}/lib/libc.so.6'"
  '';

  nativeBuildInputs = [
    python3.pkgs.setuptools
    pkgs.pandoc # not needed for later versions
  ];

  buildInputs = [
    pkgs.systemd
  ];

  propagatedBuildInputs = [
    python3.pkgs.pexpect
    pkgs.bubblewrap
    pkgs.systemd
  ];

  postInstall = ''
    wrapProgram $out/bin/mkosi \
      --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  doCheck = false;
  disabledTests = [
    "test_os_distribution"
    "test_centos_brtfs"
  ];

  checkInputs = [
    python3.pkgs.pytestCheckHook
    pkgs.systemd
  ];

  meta = with lib; {
    description = "Build legacy-free OS images";
    homepage = "https://github.com/systemd/mkosi";
    license = licenses.lgpl21;
    maintainers = with maintainers; [onny];
  };
}
