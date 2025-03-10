unit Config.Server;

interface

uses
  Generics.Collections, SysUtils, IOUtils, Bcl.Json.Attributes, Bcl.Json.NamingStrategies, Bcl.Json, Bcl.Logging,
  Config.Secrets;

type
  [JsonManaged]
  [JsonInclude(TInclusionMode.NonDefault)]
  TJwtMiddlewareConfig = class
  strict private
    FExpectedIssuers: TList<string>;
    FExpectedAudiences: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    property ExpectedIssuers: TList<string> read FExpectedIssuers;
    property ExpectedAudiences: TList<string> read FExpectedAudiences;
  end;

  TMiddlewareListConfig = class
  strict private
    FJwt: TJwtMiddlewareConfig;
  public
    constructor Create;
    destructor Destroy; override;
    property Jwt: TJwtMiddlewareConfig read FJwt write FJwt;
  end;

  [JsonManaged]
  [JsonInclude(TInclusionMode.NonDefault)]
  TModuleConfig = class
  strict private
    FBaseUrl: string;
    FMiddleware: TMiddlewareListConfig;
    FSigningKeyId: string;
  public
    constructor Create;
    destructor Destroy; override;
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property SigningKeyId: string read FSigningKeyId write FSigningKeyId;
    property Middleware: TMiddlewareListConfig read FMiddleware;
  end;

  [JsonManaged]
  [JsonInclude(TInclusionMode.NonDefault)]
  TWinServiceConfig = class
  strict private
    FName: string;
    FDisplayName: string;
    FDescription: string;
  public
    property Name: string read FName;
    property DisplayName: string read FDisplayName;
    property Description: string read FDescription;
  end;

  [JsonManaged]
  [JsonInclude(TInclusionMode.NonDefault)]
  TServerConfig = class
  private
    FApiModule: TModuleConfig;
    FAuthModule: TModuleConfig;
    FRSAKeysFolder: string;
    FSecretsFile: string;
    FWinService: TWinServiceConfig;
    function FullFolder(const Value: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function FullRSAKeysFolder: string;
    function FullSecretsFile: string;

    property SecretsFile: string write FSecretsFile;
    property ApiModule: TModuleConfig read FApiModule;
    property AuthModule: TModuleConfig read FAuthModule;
    property WinService: TWinServiceConfig read FWinService;
  end;

function ServerConfig: TServerConfig;
procedure ReloadServerConfig(const FileName: string);
procedure CheckServerConfig;

implementation

var
  _ServerConfig: TServerConfig;

procedure CheckNotEmpty(const Name, Value: string);
begin
  if Value = '' then
    raise Exception.CreateFmt('Configuration parameter "%s" must not be empty', [Name]);
end;

procedure CheckServerConfig;
begin
  if not TFile.Exists(ServerConfig.FullSecretsFile) then
    raise Exception.Create('Invalid secrets file: ' + ServerConfig.FullSecretsFile);
  CheckNotEmpty('ApiModule.BaseUrl', ServerConfig.ApiModule.BaseUrl);
  CheckNotEmpty('AuthModule.BaseUrl', ServerConfig.AuthModule.BaseUrl);
end;

function ServerConfigFileName(Suffix: string = ''): string;
var
  JsonFileName: string;
  Dir: string;
begin
  JsonFileName := TPath.GetFileName(TPath.ChangeExtension(ParamStr(0), Format('%s.json', [Suffix])));
  Dir := TPath.GetDirectoryName(ParamStr(0));

  Result := TPath.Combine(Dir, JsonFileName);
  if TFile.Exists(Result) then
    Exit;

  Result := TPath.GetFullPath(TPath.Combine(Dir, '..\..\config\local'));
  Result := TPath.Combine(Result, JsonFileName);
  if TFile.Exists(Result) then
    Exit;

  raise Exception.CreateFmt('Config file %s not found', [JsonFileName]);
end;

procedure ReloadServerConfig(const FileName: string);
begin
  FreeAndNil(_ServerConfig);
  if TFile.Exists(FileName) then
    try
      _ServerConfig := TJson.Deserialize<TServerConfig>(TFile.ReadAllText(FileName));
    except
      on E: Exception do
        LogManager.GetLogger.Error(Format('Error reading config file %s: %s (%s)', [TPath.GetFileName(FileName), E.Message, E.ClassName]));
    end
  else
    _ServerConfig := TServerConfig.Create;
  SetSecretsConfigFileName(_ServerConfig.FullSecretsFile);
end;

function ServerConfig: TServerConfig;
begin
  if _ServerConfig = nil then
    ReloadServerConfig(ServerConfigFileName);
  Result := _ServerConfig;
end;

{ TServerConfig }

constructor TServerConfig.Create;
begin
  inherited Create;
  FApiModule := TModuleConfig.Create;
  FAuthModule := TModuleConfig.Create;
  FWinService := TWinServiceConfig.Create;
end;

destructor TServerConfig.Destroy;
begin
  FApiModule.Free;
  FAuthModule.Free;
  FWinService.Free;
  inherited;
end;

function TServerConfig.FullFolder(const Value: string): string;
begin
  if TPath.IsRelativePath(Value) then
    Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), Value)
  else
    Result := Value;
end;

function TServerConfig.FullRSAKeysFolder: string;
begin
  Result := FullFolder(FRSAKeysFolder);
end;

function TServerConfig.FullSecretsFile: string;
begin
  Result := FullFolder(FSecretsFile);
end;

{ TJwtMiddlewareConfig }

constructor TJwtMiddlewareConfig.Create;
begin
  FExpectedIssuers := TList<string>.Create;
  FExpectedAudiences := TList<string>.Create;
end;

destructor TJwtMiddlewareConfig.Destroy;
begin
  FExpectedIssuers.Free;
  FExpectedAudiences.Free;
  inherited;
end;

{ TModuleConfig }

constructor TModuleConfig.Create;
begin
  FMiddleware := TMiddlewareListConfig.Create;
end;

destructor TModuleConfig.Destroy;
begin
  FMiddleware.Free;
  inherited;
end;

{ TMiddlewareListConfig }

constructor TMiddlewareListConfig.Create;
begin
  FJwt := TJwtMiddlewareConfig.Create;
end;

destructor TMiddlewareListConfig.Destroy;
begin
  FJwt.Free;
  inherited;
end;

initialization
  _ServerConfig := nil;

finalization
  _ServerConfig.Free;

end.
