unit AdditU;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, Buttons;

type
  TForm2 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    ListView1: TListView;
    ListView2: TListView;
    ListView3: TListView;
    TabSheet4: TTabSheet;
    ListView4: TListView;
    StatusBar1: TStatusBar;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1Click(Sender: TObject);
    procedure ListView1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView3DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  flag: Boolean;

implementation

uses SysInfoU, TlHelp32;

{$R *.DFM}

procedure ViewHeap;
var
  lpBuf: array of Char;
  nRead: cardinal;
  hFile: THandle;
  nWri: Cardinal;
begin
  Toolhelp32ReadProcessMemory(Cardinal(StrToInt(Form1.ListView1.Selected.SubItems[0])),
    Pointer(StrToInt(Form2.ListView3.Selected.SubItems[1])), lpBuf,
    StrToInt(Form2.ListView3.Selected.SubItems[0]), nRead);
  hFile:= CreateFile('a.txt', GENERIC_WRITE, FILE_SHARE_WRITE, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile <> INVALID_HANDLE_VALUE then
    WriteFile(hFile, lpBuf, SizeOf(lpBuf), nWri, nil);
  CloseHandle(hFile);
end;

{-----------------------------EVENT HANDLERS------------------------------}

procedure TForm2.BitBtn1Click(Sender: TObject);
begin
  flag:= true;
  Form2.Hide;
end;

procedure TForm2.BitBtn1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then Form2.Hide;
end;

procedure TForm2.ListView1Click(Sender: TObject);
begin
  with (Sender as TListView) do
   if Selected <> nil then
     StatusBar1.SimpleText:= Selected.SubItems[4];
end;

procedure TForm2.ListView1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  ListView1Click(ListView1);
end;

procedure TForm2.ListView3DblClick(Sender: TObject);
begin
  ViewHeap;
end;

end.
