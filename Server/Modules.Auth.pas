unit Modules.Auth;

interface

uses
  System.SysUtils, System.Classes, Sparkle.HttpServer.Module, Sparkle.HttpServer.Context, Sphinx.Server.Module,
  Sparkle.Comp.Server, XData.Comp.Server, Sphinx.Comp.Server, Sphinx.Comp.Config,
  System.Hash, Sparkle.Comp.CompressMiddleware, Sparkle.Comp.LoggingMiddleware, Sparkle.Comp.ForwardMiddleware,
  Config.Secrets;

type
  TAuthModule = class(TDataModule)
    SphinxConfig: TSphinxConfig;
    SphinxServer: TSphinxServer;
    SphinxServerForward: TSparkleForwardMiddleware;
    SphinxServerLogging: TSparkleLoggingMiddleware;
    SphinxServerCompress: TSparkleCompressMiddleware;
    procedure SphinxConfigGetClient(Sender: TObject; Client: TSphinxClientApp; var Accept: Boolean);
    procedure SphinxConfigGetSigningData(Sender: TObject; Args: TGetSigningDataArgs);
    procedure DataModuleCreate(Sender: TObject);
    procedure SphinxConfigConfigureToken(Sender: TObject; Args: TConfigureTokenArgs);
  public
  end;

var
  AuthModule: TAuthModule;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses
  System.TimeSpan, System.StrUtils, Config.Server, Utils.RSAKeyStorage, Bcl.Logging, Bcl.Json.Classes, Sphinx.Consts;

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TAuthModule.DataModuleCreate(Sender: TObject);
begin
  SphinxServer.BaseUrl := ServerConfig.AuthModule.BaseUrl;

  LogManager.GetLogger.Info(Format('Secrets file: total of %d client secrets configured', [SecretsConfig.Clients.Count]));

  RSAKeyStorage := TRSAKeyStorage.Create(ServerConfig.FullRSAKeysFolder);
end;

procedure TAuthModule.SphinxConfigConfigureToken(Sender: TObject; Args: TConfigureTokenArgs);
begin
  // Add client audience
  var Audiences := SplitString(Args.Client.GetParam(JwtClaimNames.Audience), ',');
  if Length(Audiences) = 1 then
    Args.Token.Claims.AddOrSet(JwtClaimNames.Audience, Audiences[0])
  else
  if Length(Audiences) > 1 then
  
  begin
    var AudienceClaim := Sparkle.Security.TUserClaim.Create(JwtClaimNames.Audience);
    Args.Token.Claims.AddOrSet(AudienceClaim);
    var JAudiences := TJArray.Create;
    AudienceClaim.SetJElement(JAudiences);
    for var Aud in Audiences do
      JAudiences.Add(Aud);
  end;

  // add email and code if present
  var Email := Args.Client.GetParam('email');
  var Code := Args.Client.GetParam('code');
  if (Email <> '') and (Code <> '') then
  begin
    Args.Token.Claims.AddOrSet('email', Email);
//    Args.Token.Claims.AddOrSet('code', Code);

    // Remove the client_id claim
    Args.Token.Claims.Remove(JwtClaimNames.ClientId);
  end;

end;

procedure TAuthModule.SphinxConfigGetClient(Sender: TObject; Client: TSphinxClientApp; var Accept: Boolean);
begin
  // Reject by default
  Accept := False;

  // First check if the client is a valid admin client
  begin
    var Config := SecretsConfig.FindClient(Client.ClientId);
    if Config <> nil then
    begin
      Accept := True;
      Client.RequireClientSecret := True;
      Client.AddSha256Secret(THashSHA2.GetHashBytes(Config.ClientSecret));
      Client.AccessTokenLifetimeSpan := TTimeSpan.FromHours(1);
      Client.AllowedGrantTypes := [TGrantType.gtClientCredentials];
      Client.ValidScopes.AddStrings(SplitString(Config.Scope, ' '));
      Client.DefaultScopeValues.Assign(Client.ValidScopes);
      Client.AddCustomParam(JwtClaimNames.Audience, string.Join(',', Config.Audiences.ToArray));
      Exit;
    end
  end;
end;

procedure TAuthModule.SphinxConfigGetSigningData(Sender: TObject; Args: TGetSigningDataArgs);
begin
  Args.Data.Algorithm := 'RS256';
  Args.Data.KeyId := ServerConfig.AuthModule.SigningKeyId;
  Args.Data.Key := RSAKeyStorage.PrivateKey(Args.Data.KeyId);
end;

end.
