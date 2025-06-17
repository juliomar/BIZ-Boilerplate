program WinServer;

uses
  Sparkle.App,
  Vcl.Forms,
  Modules.Api in 'Modules.Api.pas' {MainModule: TDataModule},
  Services.Sample in 'shared\Services.Sample.pas',
  Modules.Config in 'Modules.Config.pas' {ConfigModule: TDataModule},
  Config.Server in 'Config.Server.pas',
  Services.Sample.Impl in 'Services.Sample.Impl.pas',
  Modules.Auth in 'Modules.Auth.pas' {AuthModule: TDataModule},
  Config.Secrets in 'Config.Secrets.pas',
  Utils.RSAKeyStorage in 'Utils.RSAKeyStorage.pas',
  Services.ProblemDetail in 'Services.ProblemDetail.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TConfigModule, ConfigModule);
  Application.CreateForm(TMainModule, MainModule);
  Application.CreateForm(TAuthModule, AuthModule);
  Application.Run;
end.
