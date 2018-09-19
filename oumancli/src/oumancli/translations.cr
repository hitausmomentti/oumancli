module Oumancli
  CODES = {} of String => Hash(String, String)
  CODES["fi"] = {
    "timestamp" => "Aikaleima",
    "S_227_85"  => "Ulkolämpötila",
    "S_1000_0"  => "Lämpötaso",
    "S_261_85"  => "Huonelämpötila",
    "S_278_85"  => "Huonelämpötila (säätimen määräämä)",
    "S_259_85"  => "L1-Menoveden lämpötila",
    "S_275_85"  => "L1-Menoveden lämpötila (säätimen määräämä)",
    "S_284_85"  => "L1-Huonelämpötila",
    "S_274_85"  => "Huonelämpökaukoasetus TMR/SP",
    "S_272_85"  => "L1-Venttiilin asento",
    "S_26_85"   => "Trendin näytteenottoväli",
    "S_81_85"   => "L1-patterilämmitys: Asetettu Huonelämpötila",
    "S_87_85"   => "L1-patterilämmitys: Lämmönpudotus (huonelämpö)",
    "S_88_85"   => "L1-patterilämmitys: Suuri lämmönpudotus (huonelämpö)",
    "S_54_85"   => "L1-patterilämmitys: Menoveden minimiraja",
    "S_55_85"   => "Menoveden maksimiraja",
    "S_61_85"   => "L1-säätökäyrä -20",
    "S_63_85"   => "L1-säätökäyrä 0",
    "S_65_85"   => "L1-säätökäyrä +20",
    "S_260_85"  => "Menovesi säätökäyrän mukaan",
    "S_263_85"  => "Huonekompensoinnin vaikutus",
    "S_264_85"  => "Huonekompensoinnin aikakorjaus",
    "S_262_85"  => "L1-patterilämmitys: Hidastettu huonelämpötilamittaus",
    "S_92_85"   => "L1-Patterilämmitys: Käsiajo, sähköinen",
    "S_258_85"  => "Ulkolämpötilan hid. vaik.",
    "S_102_85"  => "Huonelämpötilan hienosäätö",
    "S_135_85"  => "Kotona/poissa-ohjaus",
    "S_222_85"  => "Kotona/poissa-ohjaus (tämä ja S_135_85 asetetaan)",
    "S_265_85"  => "Syyskuivauksen vaikutus",
  }
  CODES["en"] = {
    "timestamp" => "Timestamp",
    "S_227_85"  => "Outside temperature",
    "S_261_85"  => "Room temperature",
    "S_278_85"  => "Room temperature (as set)",
    "S_259_85"  => "L1 Outgoing water temperature",
    "S_275_85"  => "L1 Outgoing water temperature (as set)",
  }

  VALUES = {} of String => Hash(String, Hash(String, String))
  VALUES["fi"] = {"S_135_85" => {"2" => "Ei K-P-ohjausta", "0" => "Kotona", "1" => "Poissa"},
                  "S_1000_0" => {"L1 Normaalilämpö(K-P ohjaus)" => "L1-Normaalilämpö (K-P-ohjaus)", "L1 Normaalilämpö" => "L1-Normaalilämpö"},
  }
  VALUES["en"] = {"S_1000_0" => {"L1 Normaalilämpö(K-P ohjaus)" => "L1 Normal temperature (Home/Away)", "L1 Normaalilämpö" => "L1 Normal temperature"}}

  TERMS = {} of String => Hash(String, String)
  TERMS["fi"] = {
    "outside"       => "Ulkona",
    "inside"        => "Sisällä",
    "setTemp"       => "Pyyntö",
    "badReply"      => "Lämmönsäädin vastasi kummallisella tavalla",
    "error"         => "Virhe",
    "noConf"        => "Ei asetustiedostoa",
    "exampleConfAt" => "Esimerkkiasetustiedosto ",
    "noserver"      => "Säätimeen ei saa yhteyttä",
    "badlogin"      => "Väärä käyttäjätunnus tai salasana",
    "badtemp"       => "Lämpötilan pitää olla 10.0 - 29.9",

    "usage" => <<-EOF,
                ouman

                Komennot:
                    set 21.0    aseta lämpötila
                    json        tulosta JSONina
                    full        tulosta selkokielisenä
                    local-json  tulosta JSON selkokielisenä
                    codemap     näytä koodien selitykset
                    version     näytä versio
                EOF
    "badconfig" => "Virheelliset asetukset",
    }
  TERMS["en"] = {
    "outside"       => "Outside",
    "inside"        => "Inside",
    "setTemp"       => "Set to",
    "badReply"      => "The controller replied in an odd fashion",
    "error"         => "Error",
    "noConf"        => "No config file",
    "exampleConfAt" => "An example configuration file at ",
    "noserver"      => "Can't connect to the controller",
    "badlogin"      => "Bad username or password",
    "badconfig"     => "Bad configuration",
    "badtemp"       => "Temperature must be between 10.0 - 29.9",
    "usage"         => <<-EOF
              ouman

              Commands:
                  set 21.0    set the temperature
                  json        print JSON
                  full        print human-readable data
                  local-json  print JSON with human-readable data
                  codemap     show code meanings
                  version     print version
              EOF
  }
end
