unit Modules.Config;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  Bcl.Logging, Bcl.TMSLogging, TMSLoggingCore, TMSLoggingUtils, Sparkle.App.Config,
  TMSLoggingTextOutputHandler,
  TMSLoggingDiscordOutputHandler;

type
  TConfigModule = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ConfigModule: TConfigModule;

implementation

uses
  Config.Server;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TConfigModule.DataModuleCreate(Sender: TObject);
begin
  // Output log to file
  RegisterTMSLogger;
  begin
    var Handler := TMSDefaultLogger.RegisterOutputHandlerClass(TTMSLoggerTextOutputHandler);
    Handler.LogLevelFilters := [Warning, Error, Exception, Info];
    TTMSLoggerTextOutputHandler(Handler).FileName := TPath.ChangeExtension(ParamStr(0), '.log');
  end;

  // logging file config
  var LoggingFile := TPath.ChangeExtension(ParamStr(0), '.logging.ini');
  if TFile.Exists(LoggingFile) then
    TMSDefaultLogger.LoadConfigurationFromFile(nil, LoggingFile);

  // Service naming
  SparkleAppConfig.WinService.Name := ServerConfig.WinService.Name;
  SparkleAppConfig.WinService.DisplayName := ServerConfig.WinService.DisplayName;
  SparkleAppConfig.WinService.Description := ServerConfig.WinService.Description;
end;

end.
