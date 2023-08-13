{
  lib,
  pkgs,
  fetchFromGitHub,
  python3,
  stdenv,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "mkosi";
  version = "14";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "systemd";
    repo = "mkosi";
    rev = "b37ea9bc02e774502f80f3a622b0fe999e193c35";
    hash = "sha256-6Mu0pvW6izSpjePkZXZ27DsukfMfFvLoDsmn599WW7I=";
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
