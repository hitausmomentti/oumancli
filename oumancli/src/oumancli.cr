require "./oumancli/*"
require "http/client"
require "json"
require "colorize"

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
      @oumanhttp = HTTP::Client.new(@oumanAddr, @oumanPort)
      @oumanhttp.read_timeout = 2
      @time = Time.utc
    end

    def operate(path : String, time = true)
      begin
        if time
          response = @oumanhttp.get(path + @time.to_s("%a, %d %b %Y %H:%M:%S GMT").gsub(" ", "%20"))
        else
          response = @oumanhttp.get(path)
        end
      rescue pex : Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        STDERR.puts pex
        return nil
      rescue ex
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        STDERR.puts ex
        puts response
        return nil
      end
      if response.is_a?(Nil)
        return nil
      end
      if (response.body.lines.size > 1) || (response.status_code != 200)
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        return nil
      end
      return response
    end

    def parseRspKV(kvpair : String)
      k, v = kvpair.split("=")
      case k
      when "S_135_85"
        v2 = HomeAway.new(v.to_i32) if v.to_i32?
      when "S_59_85"  
        v2 = CtlMode.new(v.to_i32) if v.to_i32?
      else
        if v.to_i32?
          v2 = v.to_i32
        elsif v.to_f32?
          v2 = v.to_f32
        end
      end
      
      return k, v2 || v
    end

    def getAll
      oumanGetAll = "/request?S_227_85;S_135_85;S_1000_0;S_261_85;S_278_85;S_259_85;S_275_85;S_102_85;S_284_85;S_274_85;S_272_85;S_26_85;S_81_85;S_87_85;S_88_85;S_54_85;S_55_85;S_61_85;S_63_85;S_65_85;S_260_85;S_263_85;S_264_85;S_262_85;S_92_85;S_59_85;S_258_85;S_265_85;"

      response = operate(oumanGetAll)
      if !response
        exit 1
      end

      res = Hash(String, String | Float32 | Int32 | HomeAway | CtlMode).new
      res["timestamp"] = @time.to_s("%Y-%m-%dT%H:%M:%S%z")

      begin
        /request\?([^\x00]*);/.match(response.body.lines[0])

        $1.split(";").each do |i|
          k, v = parseRspKV(i)
          res[k] = v
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
        if v.is_a?(Float32)
          v = sprintf("%.1f", v)
        end
        puts k.rjust(len) + " : " + v.to_s
      end
    end

    def codestowords
      h = getAll()
      res = Hash(String, String | Float32 | Int32 | HomeAway | CtlMode).new
      h.each do |k, v|
        if VALUES[@lang][k]? && VALUES[@lang][k][v]?
          v = VALUES[@lang][k][v]
        end
        if CODES[@lang]? && CODES[@lang][k]?
          res[CODES[@lang][k]] = v
        else
          res[k] = v
        end
      end
      return res
    end

    def print_summary
      data = getAll()

      t = data["S_227_85"].to_f32
      if t <= -15.0
        t_out = sprintf("%.1f", t).colorize.fore(:light_cyan).mode(:bold)
      elsif t < 0
        t_out = sprintf("%.1f", t).colorize.fore(:light_cyan)
      elsif t >= 15
        t_out = sprintf("%.1f", t).colorize.fore(:yellow)
      elsif t >= 25
        t_out = sprintf("%.1f", t).colorize.fore(:red).mode(:bold)
      else
        t_out = sprintf("%.1f", t)
      end

      t = data["S_261_85"].to_f32
      if t <= 10.0
        t_in = sprintf("%.1f", t).colorize.fore(:light_cyan).mode(:bold)
      elsif t < 10
        t_in = sprintf("%.1f", t).colorize.fore(:light_cyan)
      elsif t >= 23
        t_in = sprintf("%.1f", t).colorize.fore(:light_yellow)
      elsif t >= 28
        t_in = sprintf("%.1f", t).colorize.fore(:red).mode(:bold)
      else
        t_in = sprintf("%.1f", t)
      end

      s = sprintf("%s  %s   %s: %s   %s: %s   (%s: %.1f",
        @oumanAddr, Time.local.to_s("%Y-%m-%d %H:%M:%S%z"),
        TERMS[@lang]["outside"], t_out,
        TERMS[@lang]["inside"], t_in,
        TERMS[@lang]["setTemp"], data["S_81_85"])
      if data["S_265_85"] != 0
        s += sprintf(" + %.1f", data["S_265_85"])
      end
      s += ")\n"
      puts s
    end

    def parseArgs
      if ARGV.size == 0
        print_summary
        exit 0
      end
      case ARGV[0]
      when "temp"
        if (ARGV[1]?) && (t = ARGV[1].to_f32?)
          setTemp(t)
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
      when "valve"
        s = nil unless (ARGV[2]? && (s = ARGV[2].to_i32?))

        if ARGV[1]?
          case ARGV[1]
          when "manual"
            setValve(CtlMode::Manual, s)
          when "auto"
            setValve(CtlMode::Auto, s) 
          else
            puts TERMS[@lang]["usage"]
            exit 1
          end
        else
          STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badmode"]
          exit 1
        end
        
      else
        puts TERMS[@lang]["usage"]
      end
    end

    def login
      response = operate("/login?uid=" + @username + ";pwd=" + @password + ";")
      if !response
        exit 1
      end
      /login\?([^\x00]*);/.match(response.body.lines[0])

      res = {} of String => String
      res["timestamp"] = @time.to_s("%Y-%m-%d/%H:%M:%S%z")

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
      if temp < 10 || temp >= 35
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badtemp"]
        exit 1
      end
      t_str = sprintf("%.1f", temp) # floats and locales
      login()
      response = operate("/update?@_S_81_85=" + t_str + ";")
      if !response
        exit 1
      end

      /result\?([^\x00]*);/.match(response.body.lines[0])

      res = {} of String => String
      res["timestamp"] = @time.to_s("%Y-%m-%d %H:%M:%S%z")

      $1.split(";").each do |i|
        k, v = i.split("=")
        res[k] = v
      end
      if !res["S_81_85"].to_f32? || res["S_81_85"].to_f32 != temp
        STDERR.puts TERMS[@lang]["err_tempchg"] + " " + res["S_81_85"]
        exit 1
      end
      puts res["timestamp"] + "  OK: " + t_str
      return res
    end

    def setValve(mode : CtlMode, setting : (Int32 | Nil) = nil)
      if !(mode.takesNumber? == !!setting)
        STDERR.puts TERMS[@lang]["badmodecombo"]
        exit 1
      end
      if mode.takesNumber? && setting
        if setting < 1 || setting > 100
          STDERR.puts TERMS[@lang]["badvalve"]
          exit 1
        end
        login
        operate("/update?S_59_85=#{mode.value};S_92_85=#{setting};")
      else
        login
        operate("/update?S_59_85=#{mode.value};")
      end
    end

    def getserverversion
      begin
        response = @oumanhttp.get("/")
      rescue Socket::Error
        STDERR.puts TERMS[@lang]["noserver"] + "\n" + @oumanAddr
        exit 1
      rescue
        STDERR.puts TERMS[@lang]["error"]
        puts response
        exit 1
      end
      if response.is_a?(Nil) || response.status_code != 200
        STDERR.puts TERMS[@lang]["error"] + ". " + TERMS[@lang]["badReply"]
        exit 1
      end
      ex = /<title>([^<>]+)/
      ex.match(response.body)
      return $1
    end
  end

  Colorize.enabled = STDOUT.tty?
  STDIN.blocking = !(STDIN.class == IO)
  ouman = Ouman.new(ENV["HOME"] + "/.oumanrc")
  ouman.parseArgs
end

# staattisuusklunssi https://github.com/j8r/dockerfiles/tree/master/crystal-alpine
# require "llvm/lib_llvm"
# require "llvm/enums"
