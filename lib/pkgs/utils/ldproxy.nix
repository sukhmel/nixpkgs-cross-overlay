{ lib, fetchCrate, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "ldproxy";
  version = "0.3.3";

  src = fetchCrate {
    inherit pname version;
    sha256 = "sha256-XLfa40eMkeUL544gDqZYbly2E5Mrogn7v24D8u/wjkg=";
  };

  cargoHash = "sha256-orWs8KYFUtMp5vbwhr3O13FGXjXXKZ6Idp+ZS538P+Y=";

  meta = with lib; {
    description = "A linker proxy tool";
    homepage = "https://github.com/esp-rs/embuild";
    license = licenses.mit;
    maintainers = [ maintainers.alekseysidorov ];
  };
}
