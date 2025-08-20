{ mkEnvHook
, pkgs
, cyrus_sasl
}:

mkEnvHook {
  name = "cargo-sasl2-sys";

  propagatedBuildInputs = [
    pkgs.pkgsBuildHost.pkg-config
  ];
  depsTargetTargetPropagated = [
    cyrus_sasl
  ];
}
