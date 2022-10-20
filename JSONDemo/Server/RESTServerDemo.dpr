program RESTServerDemo;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {RestServerForm},
  Vcl.Themes,
  Vcl.Styles,
  CustomerClass in '..\CustomerClass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Glossy');
  Application.CreateForm(TRestServerForm, RestServerForm);
  Application.Run;
end.
