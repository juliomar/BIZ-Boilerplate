unit Config.Secrets;

interface

uses
  System.Generics.Collections, System.SysUtils, System.IOUtils,
  Bcl.Json, Bcl.Logging, Bcl.Collections;

type
  TClientConfig = class
  strict private
    FClientName: string;
    FClientId: string;
    FClientSecret: string;
    FScope: string;
    FAudiences: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    property ClientName: string read FClientName write FClientName;
    property ClientId: string read FClientId write FClientId;
    property ClientSecret: string read FClientSecret write FClientSecret;
    property Scope: string read FScope write FScope;
    property Audiences: TList<string> read FAudiences write FAudiences;
  end;

  TSecretValues = TOrderedDictionary<string, string>;

  TSecretsConfig = class
  private
    FClients: TList<TClientConfig>;
    FEnvVarPrefix: string;
  public
    constructor Create;
    destructor Destroy; override;
    function FindClient(const ClientId: string): TClientConfig;
    property Clients: TList<TClientConfig> read FClients;
    property EnvVarPrefix: string read FEnvVarPrefix;
  end;

procedure SetSecretsConfigFileName(const FileName: string);
function SecretsConfig: TSecretsConfig;

implementation

var
  _SecretsConfigFileName: string;
  _SecretsConfig: TSecretsConfig;

procedure SetSecretsConfigFileName(const FileName: string);
begin
  _SecretsConfigFileName := FileName;
  FreeAndNil(_SecretsConfig);
end;

function SecretsConfig: TSecretsConfig;
begin
  if _SecretsConfig = nil then
  begin
    var ConfigFile := _SecretsConfigFileName;
    if TFile.Exists(ConfigFile) then
      try
        _SecretsConfig := TJson.Deserialize<TSecretsConfig>(TFile.ReadAllText(ConfigFile));
      except
        on E: Exception do
          LogManager.GetLogger.Error(Format('Error reading secrets config file %s: %s (%s)', [TPath.GetFileName(ConfigFile), E.Message, E.ClassName]));
      end
    else
      _SecretsConfig := TSecretsConfig.Create;
  end;
  Result := _SecretsConfig;
end;

{ TClientConfig }

constructor TClientConfig.Create;
begin
  FAudiences := TList<string>.Create;
end;

destructor TClientConfig.Destroy;
begin
  FAudiences.Free;
  inherited;
end;

{ TSecretsConfig }

constructor TSecretsConfig.Create;
begin
  FClients := TObjectList<TClientConfig>.Create;
end;

destructor TSecretsConfig.Destroy;
begin
  FClients.Free;
  inherited;
end;

function TSecretsConfig.FindClient(const ClientId: string): TClientConfig;
begin
  for var Client in Clients do
    if Client.ClientId = ClientId then
      Exit(Client);
  Result := nil;
end;

initialization
  _SecretsConfig := nil;
  _SecretsConfigFileName := '';

finalization
  _SecretsConfig.Free;

end.
