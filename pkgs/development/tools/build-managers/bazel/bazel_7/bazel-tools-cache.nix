# @@bazel_tools//tools/proto:all
{ lib
, bazel
, stdenv
, version
, jdk17_headless
, outputHash ? lib.fakeHash
}:
stdenv.mkDerivation {
  pname = "bazel_tools_cache";
  inherit version;
  dontUnpack = true;
  buildInputs = [ jdk17_headless ];
  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir repository_cache
    touch WORKSPACE MODULE.bazel
    ${lib.getExe' bazel "bazel"} fetch \
      --repository_cache=$(pwd)/repository_cache \
      --verbose_failures \
      --curses=no \
      @@bazel_tools//tools/proto:all \
      @@apple_support~//crosstool # TODO: move apple support somewhere else

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv repository_cache/content_addressable $out

    runHook postInstall
  '';
  outputHashMode = "recursive";
  inherit outputHash;
}
