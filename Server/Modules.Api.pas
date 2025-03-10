unit Modules.Api;

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes, Sparkle.HttpServer.Module, Sparkle.HttpServer.Context,
  Sparkle.Comp.Server, XData.Comp.Server, Sparkle.Comp.GenericMiddleware, Sparkle.Comp.LoggingMiddleware,
  XData.Server.Module, Config.Server, Sparkle.Comp.JwtMiddleware,
  Sparkle.Comp.ForwardMiddleware, Sparkle.Comp.CompressMiddleware;

type
  TMainModule = class(TDataModule)
    ApiServer: TXDataServer;
    ApiServerLogging: TSparkleLoggingMiddleware;
    ApiServerJWT: TSparkleJwtMiddleware;
    ApiServerForward: TSparkleForwardMiddleware;
    ApiServerCompress: TSparkleCompressMiddleware;
    ApiServerGeneric: TSparkleGenericMiddleware;
    procedure DataModuleCreate(Sender: TObject);
    procedure JWTGetSecretEx(Sender: TObject; const JWT: TJWT; Context: THttpServerContext;
      var Secret: TBytes);
    procedure ApiServerGenericRequest(Sender: TObject; Context: THttpServerContext; Next: THttpServerProc);
  private
    procedure ConfigureJwtMiddleware(Config: TJwtMiddlewareConfig; Middleware: TSparkleJwtMiddleware);
  public
  end;

var
  MainModule: TMainModule;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses
  System.IOUtils, Bcl.Jose.Consumer, Bcl.Utils, Bcl.Logging, Bcl.Json.BaseObjectConverter,
  Utils.RSAKeyStorage;

{$R *.dfm}

procedure TMainModule.DataModuleCreate(Sender: TObject);
begin
  // Set servers properties based on config file
  ApiServer.BaseUrl := ServerConfig.ApiModule.BaseUrl;
  ConfigureJWTMiddleware(ServerConfig.ApiModule.Middleware.Jwt, ApiServerJWT);

  // Check cofig
  CheckServerConfig;

  // Log start
  var Logger := LogManager.GetLogger;
  Logger.Info('Api data module created');
end;

procedure TMainModule.JWTGetSecretEx(Sender: TObject; const JWT: TJWT; Context: THttpServerContext;
  var Secret: TBytes);
begin
  if JWT.Header.Algorithm = 'RS256' then
    Secret := RSAKeyStorage.PublicKey(JWT.Header.KeyID)
  else
    raise EInvalidJWTException.CreateFmt(
      'JWS algorithm [%s] is not supported', [JWT.Header.Algorithm]);
end;

procedure TMainModule.ApiServerGenericRequest(Sender: TObject; Context: THttpServerContext; Next: THttpServerProc);
begin
  Context.Response.OnHeaders(
    procedure(Response: THttpServerResponse)
    begin
      Response.Headers.SetValue('Server-Version', '1');
    end);
  Next(Context);
end;

procedure TMainModule.ConfigureJwtMiddleware(Config: TJwtMiddlewareConfig; Middleware: TSparkleJwtMiddleware);
begin
  Middleware.RequireExpirationTime := True;
  Middleware.AllowExpiredToken := False;
  Middleware.ForbidAnonymousAccess := False;

  for var Issuer in Config.ExpectedIssuers do
    Middleware.ExpectedIssuers.Add(Issuer);
  if Middleware.ExpectedIssuers.Count = 0 then
    Middleware.ExpectedIssuers.Add('Unknown');

  for var Audience in Config.ExpectedAudiences do
    Middleware.ExpectedAudiences.Add(Audience);
  if Middleware.ExpectedAudiences.Count = 0 then
    Middleware.ExpectedAudiences.Add('Unknown');
end;

end.
