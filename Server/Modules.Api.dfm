object MainModule: TMainModule
  OnCreate = DataModuleCreate
  Height = 394
  Width = 602
  object ApiServer: TXDataServer
    UnknownMemberHandling = Error
    InstanceLoopHandling = Error
    EntitySetPermissions = <>
    SwaggerOptions.Enabled = True
    SwaggerUIOptions.Enabled = True
    Left = 56
    Top = 56
    object ApiServerGeneric: TSparkleGenericMiddleware
      OnRequest = ApiServerGenericRequest
    end
    object ApiServerForward: TSparkleForwardMiddleware
    end
    object ApiServerLogging: TSparkleLoggingMiddleware
      FormatString = ':method :url :statuscode - :responsetime ms'
      ExceptionFormatString = '(%1:s: %4:s) %0:s - %2:s'
      ErrorResponseOptions.ErrorCode = 'ServerError'
      ErrorResponseOptions.ErrorMessageFormat = 'Internal server error: %4:s'
    end
    object ApiServerCompress: TSparkleCompressMiddleware
    end
    object ApiServerJWT: TSparkleJwtMiddleware
      ForbidAnonymousAccess = True
      OnGetSecretEx = JWTGetSecretEx
    end
  end
end
