object AuthModule: TAuthModule
  OnCreate = DataModuleCreate
  Height = 364
  Width = 516
  object SphinxConfig: TSphinxConfig
    Clients = <>
    OnGetClient = SphinxConfigGetClient
    OnConfigureToken = SphinxConfigConfigureToken
    OnGetSigningData = SphinxConfigGetSigningData
    Left = 80
    Top = 48
  end
  object SphinxServer: TSphinxServer
    Config = SphinxConfig
    Left = 80
    Top = 128
    object SphinxServerForward: TSparkleForwardMiddleware
    end
    object SphinxServerLogging: TSparkleLoggingMiddleware
      FormatString = ':method :url :statuscode - :responsetime ms'
      ExceptionFormatString = '(%1:s: %4:s) %0:s - %2:s'
      ErrorResponseOptions.ErrorCode = 'ServerError'
      ErrorResponseOptions.ErrorMessageFormat = 'Internal server error: %4:s'
    end
    object SphinxServerCompress: TSparkleCompressMiddleware
    end
  end
end
