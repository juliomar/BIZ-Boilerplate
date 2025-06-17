unit Services.ProblemDetail;

// A sample unit that shows how to support specific custom exceptions types and responses in XData.
// Using problem details RFC as the example, according to this discussion:
// https://support.tmssoftware.com/t/rfc-7807-9457-http-status-code-400-with-data/25481
//
// To see it in action, visit URL <base_url>/problem-detail (e.g., http://localhost:2001/tms/api/problem-detail)
//
// For the sake of example, we put everything related to problem details in this single unit:
// the DTO class (THttpProblemDetail) and descendants, the exception class (EHttpProblemException),
// the OnModuleException event handler, and also a sample service described by its interface contract and
// implementation class. Ideally those concepts should be in separated units for better code organization and reuse.

interface

uses
  System.SysUtils,
  Bcl.Json,
  Bcl.Json.Attributes,
  Bcl.Json.NamingStrategies,
  XData.Module.Events,
  XData.Service.Common,
  XData.Sys.Exceptions;

type
  /// <summary>
  ///   DTO class used to hold information about the problem details and to be serialized as JSON in response
  /// </summary>
  [JsonNamingStrategy(TCamelCaseNamingStrategy)] // convert field names to lowercase
  [JsonInclude(TInclusionMode.NonDefault)] // do not include default values in JSON
  THttpProblemDetail = class
  private
    FType: string;
    FStatus: Integer;
    FTitle: string;
    FDetail: string;
    FInstance: string;
  strict protected
    function GetExceptionMessage: string; virtual;
  public
    constructor Create; overload;
    constructor Create(const AStatus: Integer); overload;
    constructor Create(const AStatus: Integer; const AType: string); overload;
    property ExceptionMessage: string read GetExceptionMessage;
    property &Type: string read FType write FType;
    property Status: Integer read FStatus write FStatus;
    property Title: string read FTitle write FTitle;
    property Detail: string read FDetail write FDetail;
    property Instance: string read FInstance write FInstance;
  end;

  THttpOutOfCreditProblem = class(THttpProblemDetail)
  private
    FBalance: Currency;
    FAccounts: TArray<string>;
  public
    property Balance: Currency read FBalance write FBalance;
    property Accounts: TArray<string> read FAccounts write FAccounts;
  end;

  /// <summary>
  ///   Exception class to be raised if we want the server response to be a problem details content (application/problem+json)
  /// </summary>
  EHttpProblemException = class(EXDataHttpException)
  strict private
  private
    FProblem: THttpProblemDetail;
  public
    constructor Create(AProblem: THttpProblemDetail);
    destructor Destroy; override;
    property Problem: THttpProblemDetail read FProblem;
  end;

  /// <summary>
  ///   Sample endpoint that returns an error in HTTP Problem Details standard
  /// </summary>
  [ServiceContract]
  [Route('problem-detail')]
  IProblemDetailSampleService = interface(IInvokable)
  ['{4CCB47A3-7EEF-4187-83F8-E6366C5B8A7C}']
    [HttpGet, Route('')] procedure RaiseProblem;
  end;

  [ServiceImplementation]
  TProblemDetailSampleService = class(TInterfacedObject, IProblemDetailSampleService)
  public
    procedure RaiseProblem;
  end;

  TProblemDetailExceptionHandler = class
  public
    class function HandleModuleException(Args: TModuleExceptionArgs): Boolean;
  end;

implementation

{ THttpProblemDetail }

function THttpProblemDetail.GetExceptionMessage: string;
begin
  Result := Detail;
  if Result = '' then
    Result := Title;
  if Result = '' then
    Result := &Type;
end;

constructor THttpProblemDetail.Create;
begin
  inherited Create;
  FType := 'about:blank';
  FStatus := 400;
end;

constructor THttpProblemDetail.Create(const AStatus: Integer);
begin
  Create;
  FStatus := AStatus;
end;

constructor THttpProblemDetail.Create(const AStatus: Integer;
  const AType: string);
begin
  Create(AStatus);
  FType := AType;
end;

{ EHttpProblemException }

constructor EHttpProblemException.Create(AProblem: THttpProblemDetail);
begin
  inherited Create(AProblem.Status, AProblem.ExceptionMessage);
  FProblem := AProblem;
end;

destructor EHttpProblemException.Destroy;
begin
  FProblem.Free;
  inherited;
end;

{ TProblemDetailSampleService }

procedure TProblemDetailSampleService.RaiseProblem;
begin
  var Problem := THttpOutOfCreditProblem.Create(400);
  Problem.&Type := 'https://example.com/probs/out-of-credit';
  Problem.Title := 'You do not have enough credit.';
  Problem.Detail := 'Your current balance is 30, but that costs 50.';
  Problem.Instance := '/account/12345/msgs/abc';
  Problem.Balance := 30;
  Problem.Accounts := ['/account/12345', '/account/67890'];
  raise EHttpProblemException.Create(Problem);
end;

{ TProblemDetailExceptionHandler }

class function TProblemDetailExceptionHandler.HandleModuleException(
  Args: TModuleExceptionArgs): Boolean;
var
  Problem: THttpProblemDetail;
begin
  if not (Args.Exception is EHttpProblemException) then
    Exit(False);

  Result := True;
  Problem := (Args.Exception as EHttpProblemException).Problem;
  Args.Handler.Response.StatusCode := Problem.Status;
  Args.Handler.Response.Headers.SetValue('content-type', 'application/problem+json');
  Args.Handler.Response.Close(TEncoding.UTF8.GetBytes(TJson.Serialize(Problem)));
end;

initialization
  RegisterServiceType(TypeInfo(IProblemDetailSampleService));
  RegisterServiceType(TProblemDetailSampleService);
end.
