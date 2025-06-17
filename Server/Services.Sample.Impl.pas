unit Services.Sample.Impl;

interface

uses
  System.SysUtils,
  XData.Service.Common,
  Services.Sample;

type
  [ServiceImplementation]
  TSampleService = class(TInterfacedObject, ISampleService)
  public
    function EchoString(const Value: string): string;
    function Add(const A, B: Double): Double;
  end;

implementation

{ TSampleService }

function TSampleService.Add(const A, B: Double): Double;
begin
  Result := A + B;
end;

function TSampleService.EchoString(const Value: string): string;
begin
  Result := Value;
end;

initialization
  RegisterServiceType(TSampleService);

end.

