unit Services.Sample;

interface

uses
  System.Classes,
  XData.Security.Attributes, XData.Service.Common;

type
  /// <summary>
  /// Sample endpoints.
  /// </summary>
  [ServiceContract]
  [Route('sample')]
  [ValidateParams]
  ISampleService = interface(IInvokable)
    ['{4A3455BB-86D5-433C-89DB-5686DA7B567A}']

    /// <summary>
    /// Echoes the provided string value.
    /// </summary>
    /// <returns>The value provided as parameter.</returns>
    [HttpGet, Route('echo')]
    function EchoString(const Value: string): string;

    /// <summary>
    /// Adds two numbers A and B.
    /// </summary>
    /// <param name="A">
    ///   Description for A parameter. Only method documentation, doesn't appear in Swagger.
    /// </param>
    /// <param name="B">
    ///   Description for B parameter. Only method documentation, doesn't appear in Swagger.
    /// </param>
    /// <returns>The sum of A ad B.</returns>
    [HttpGet, Route('add')]
    function Add(const A, B: Double): Double;
  end;

implementation

initialization
  RegisterServiceType(TypeInfo(ISampleService));

end.
