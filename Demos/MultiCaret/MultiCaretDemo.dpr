program MultiCaretDemo;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {TMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTMainForm, TMainForm);
  Application.Run;
end.
