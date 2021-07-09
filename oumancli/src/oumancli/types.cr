module Oumancli
  enum CtlMode
    Auto   = 0
    ForceTempDrop = 1
    ForceTempDropBig = 2
    ForceNormTemp = 3
    Shutdown = 5
    Manual = 6
    
    def takesNumber?
      if self == CtlMode::Manual
        true
      else
        false
      end
    end
  end

  enum HomeAway
    Home = 0
    Away = 1
    Disabled = 2 
  end


end
