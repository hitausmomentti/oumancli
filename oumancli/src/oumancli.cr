require "./oumancli/*"
require "http/client"
require "json"

module Oumancli
  class Ouman
    @lang = "en"
    @oumanAddr = ""
    @oumanPort = 80
    @username = ""
    @password = ""

    def initialize(file : String)
      if File.exists?(file)
        begin
          conf = JSON.parse(File.read(file))
        rescue JSON::ParseException
          STDERR.puts TERMS[@lang]["error"] + "\nJSON " + file
          exit 1
        end

        begin
          @lang = conf["lang"].as_s

          unless TERMS.has_key?(@lang)
            @lang = "en"
          end

          a = conf["address"].as_s.split(":")
          @oumanAddr = a[0]
          if a[1]?
            @oumanPort = a[1].to_i
          end
          @username = conf["username"].as_s
          @password = conf["password"].as_s
        rescue ex
          STDERR.puts TERMS[@lang]["badconfig"]
          STDERR.puts ex
          exit 1
        end
      else
        if !File.exists?(file + "_example")
          exampleconf = {
            "address"  => "ouman.subdomain.domain",
            "username" => "username",
            "password" => "password",
            "lang"     => "fi",
          }
          File.write(file + "_example", exampleconf.to_pretty_json)
        end
        puts TERMS[@lang]["noConf"] + "\n" + TERMS[@lang]["exampleConfAt"] + " " + file + "_example"
        exit 1
      end
    end

    def getAll
      oumanGetAll = "/request?S_227_85;S_135_85;S_1000_0;S_261_85;S_278_85;S_259_85;S_275_85;S_102_85;S_284_85;S_274_85;S_272_85;S_26_85;S_81_85;S_87_85;S_88_85;S_54_85;S_55_85;S_61_85;S_63_85;S_65_85;S_260_85;S_263_85;S_264_85;S_262_85;S_92_85;S_59_85;S_258_85;S_265_85"

      time = Time.utc_now

      begin
        client = HTTP::Client.new(@oumanAddr, @oumanPort)
        client.read_timeout = 2
        response = client.get(oumanGetAll + time.to_s("%a, %d %b %Y %H:%M:%S GMT").gsub(" ", "%20"))
      rescue pex : Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        STDERR.puts pex
        exit 1
      rescue ex
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        STDERR.puts ex
        puts response
        exit 1
      end
      if (response.body.lines.size > 1) | (response.status_code != 200)
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        exit 1
      end

      res = Hash(String, String | Float32 | Int32).new
      res["timestamp"] = time.to_s("%Y-%m-%dT%H:%M:%S%z")

      begin
        /request\?([^\x00]*);/.match(response.body.lines[0])

        $1.split(";").each do |i|
          k, v = i.split("=")
          unless k == "S_135_85"
            a = v.to_f32?
          end
          res[k] = a || v
        end
      rescue ex
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        STDERR.puts ex
        exit 1
      end

      return res
    end

    def print_pretty_json
      puts codestowords.to_pretty_json
    end

    def print_code_map
      puts CODES[@lang].to_pretty_json
    end

    def print_codes_json
      h = getAll()
      puts h.to_pretty_json
    end

    def print_pretty
      arr = codestowords
      len = 0
      puts "\n"

      arr.each do |k, v|
        if k.size > len
          len = k.size
        end
      end
      arr.each do |k, v|
        puts k.rjust(len) + " : " + v.to_s
      end
    end

    def codestowords
      h = getAll()
      res = Hash(String, String | Float32 | Int32).new
      h.each do |k, v|
        if VALUES[@lang][k]?
          if VALUES[@lang][k][v]?
            v = VALUES[@lang][k][v]
          end
        end
        if CODES[@lang]?
          if CODES[@lang][k]?
            res[CODES[@lang][k]] = v
          else
            res[k] = v
          end
        else
          res[k] = v
        end
      end
      return res
    end

    def print_summary
      data = getAll()
      puts @oumanAddr + "  " + Time.now.to_s("%Y-%m-%d %H:%M:%S%z") + "   " +
           TERMS[@lang]["outside"] + ": " + data["S_227_85"].to_s + "   " +
           TERMS[@lang]["inside"] + ": " + data["S_261_85"].to_s + " (" +
           TERMS[@lang]["setTemp"] + ": " + data["S_278_85"].to_s + ")"
    end

    def parseArgs
      if ARGV.size == 0
        print_summary
        exit 0
      end
      case ARGV[0]
      when "set"
        if (ARGV[1]?) && (ARGV[1] =~ /^[1-2]\d(\.\d)?$/)
          setTemp(ARGV[1])
          exit 0
        else
          STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badtemp"]
          exit 1
        end
      when "codemap"
        self.print_code_map
      when "json"
        self.print_codes_json
      when "local-json"
        self.print_pretty_json
      when "version"
        puts "\nOuman-cli\n\nClient: " + VERSION
        puts "Server: " + getserverversion()
      when "full"
        self.print_pretty
      else
        puts TERMS[@lang]["usage"]
      end
    end

    def login
      time = Time.utc_now
      begin
        client = HTTP::Client.new(@oumanAddr, @oumanPort)
        client.read_timeout = 5
        response = client.get("/login?uid=" + @username + ";pwd=" + @password + ";" + time.to_s("%a, %d %b %Y %H:%M:%S GMT").gsub(" ", "%20"))
      rescue Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        exit 1
      rescue ex
        STDERR.puts TERMS[@lang]["error"]
        STDERR.puts ex
        STDERR.puts response
        exit 1
      end
      if (response.body.lines.size > 1) | (response.status_code != 200)
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        exit 1
      end
      /login\?([^\x00]*);/.match(response.body.lines[0])

      res = {} of String => String
      res["timestamp"] = time.to_s("%Y-%m-%d/%H:%M:%S%z")

      $1.split(";").each do |i|
        k, v = i.split("=")
        res[k] = v
      end
      if res["result"] != "ok"
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badlogin"]
        exit 1
      end
      return res
    end

    def setTemp(temp)
      time = Time.utc_now
      temp = temp.to_f.to_s

      begin
        login
        client = HTTP::Client.new(@oumanAddr, @oumanPort)
        client.read_timeout = 5
        response = client.get("/update?@_S_81_85=" + temp + ";" + time.to_s("%a, %d %b %Y %H:%M:%S GMT").gsub(" ", "%20"))
      rescue Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        exit 1
      rescue ex
        STDERR.puts TERMS[@lang]["error"]
        STDERR.puts ex
        STDERR.puts response
        exit 1
      end
      if (response.body.lines.size > 1) | (response.status_code != 200)
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        exit 1
      end
      /result\?([^\x00]*);/.match(response.body.lines[0])

      res = {} of String => String
      res["timestamp"] = time.to_s("%Y-%m-%d/%H:%M:%S%z")

      $1.split(";").each do |i|
        k, v = i.split("=")
        res[k] = v
      end
      if res["S_81_85"] != temp
        STDERR.puts TERMS[@lang]["error"]
        exit 1
      end
      puts res["timestamp"] + "  OK: " + temp
      return res
    end

    def getserverversion
      begin
        response = HTTP::Client.get "http://" + @oumanAddr + "/"
      rescue Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        exit 1
      rescue
        STDERR.puts TERMS[@lang]["error"]
        puts response
        exit 1
      end
      if response.status_code != 200
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        exit 1
      end
      ex = /<title>([^<>]+)/
      ex.match(response.body)
      return $1
    end
  end

  STDIN.blocking = true if STDIN.class != IO
  ouman = Ouman.new(ENV["HOME"] + "/.oumanrc")
  ouman.parseArgs
end
