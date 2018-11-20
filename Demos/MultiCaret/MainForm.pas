unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEdit;

type
  TTMainForm = class(TForm)
    SynEdit1: TSynEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TMainForm: TTMainForm;

implementation

{$R *.dfm}

end.
