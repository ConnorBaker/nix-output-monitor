{
  mkDerivation,
  ansi-terminal,
  async,
  attoparsec,
  base,
  bytestring,
  cassava,
  containers,
  data-default,
  directory,
  extra,
  filepath,
  hermes-json,
  HUnit,
  lib,
  lock-file,
  MemoTrie,
  mtl,
  nix-derivation,
  optics,
  random,
  relude,
  safe,
  stm,
  streamly,
  strict,
  strict-types,
  terminal-size,
  text,
  time,
  typed-process,
  wcwidth,
  word8,
}:
mkDerivation {
  pname = "nix-output-monitor";
  version = "2.0.0.5";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    ansi-terminal
    async
    attoparsec
    base
    bytestring
    cassava
    containers
    data-default
    directory
    extra
    filepath
    hermes-json
    lock-file
    MemoTrie
    mtl
    nix-derivation
    optics
    relude
    safe
    stm
    streamly
    strict
    strict-types
    terminal-size
    text
    time
    wcwidth
    word8
  ];
  executableHaskellDepends = [
    ansi-terminal
    async
    attoparsec
    base
    bytestring
    cassava
    containers
    data-default
    directory
    extra
    filepath
    hermes-json
    lock-file
    MemoTrie
    mtl
    nix-derivation
    optics
    relude
    safe
    stm
    streamly
    strict
    strict-types
    terminal-size
    text
    time
    typed-process
    wcwidth
    word8
  ];
  testHaskellDepends = [
    ansi-terminal
    async
    attoparsec
    base
    bytestring
    cassava
    containers
    data-default
    directory
    extra
    filepath
    hermes-json
    HUnit
    lock-file
    MemoTrie
    mtl
    nix-derivation
    optics
    random
    relude
    safe
    stm
    streamly
    strict
    strict-types
    terminal-size
    text
    time
    typed-process
    wcwidth
    word8
  ];
  homepage = "https://github.com/maralorn/nix-output-monitor";
  description = "Parses output of nix-build to show additional information";
  license = lib.licenses.agpl3Plus;
  mainProgram = "nom";
}
