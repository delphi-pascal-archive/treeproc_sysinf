unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TlHelp32, ComCtrls, Grids, ImgList;

type
  TForm1 = class(TForm)
    btnPrior: TButton;
    btnTerminate: TButton;
    cbPrior: TComboBox;
    sgrInfo: TStringGrid;
    tvwProc: TTreeView;
    edID: TEdit;
    btnRecreate: TButton;
    ImageList1: TImageList;
    btnShowW: TButton;
    GroupBox1: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    btnHideW: TButton;
    Button1: TButton;
    Button2: TButton;
    // procedure btnProcClick(Sender: TObject);
    // procedure btnStreamClick(Sender: TObject);
    procedure btnTerminateClick(Sender: TObject);
    // procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    //
    procedure CreateProcessTree();
    procedure AddChild(k: integer);
    procedure AddWindow(_hwnd: longint);//pr: cardinal);//
    procedure tvwProcDblClick(Sender: TObject);
    procedure tvwProcClick(Sender: TObject);
    procedure btnRecreateClick(Sender: TObject);
    procedure btnPriorClick(Sender: TObject);
    //
    procedure btnShowWClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnHideWClick(Sender: TObject);
    procedure tvwProcKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    // procedure GetAllProc(var pr: array of TProcessEntry32);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PPe=^TProcessEntry32;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const Max_=255;

var
 //если HANDL определен лок., то при щелчке мышью(!!!)результат - He good
 SH   : Cardinal;
 DT_hWnd, buflen : longint;
 //
 all  : array of TProcessEntry32;
 n: integer;
 buf : array [0..Max_] of Char;
 prId,thId, pr : DWord;
 //
 IWV: boolean;
 //  hw: ^longint;
 hw: array[0..255] of dword;
 ihw: byte;
 thrCount: integer;

procedure TForm1.CreateProcessTree();
var
//  AllPr: array of TProcessEntry32;
  i,j,k: integer;
  PE   : TProcessEntry32;
  IsRoot: boolean;
//  NodeNew: TTreeNode;
begin
 n:=0;
 ihw:=0;
 thrCount:=0;
 SH := CreateToolHelp32SnapShot(Th32cs_SnapAll, 0);
 pe.dwSize:=sizeof(PE);//без этого она до определённого момента работала!?
 Process32First(SH, PE);
 repeat                 //найти все процессы
   SetLength(all,n+2);
   all[n]:=PE;
   inc(thrCount,all[n].cntThreads);
   inc(n);
 until not Process32Next(SH, PE);
 //построение дерева
 i:=0;
 DT_hWnd :=GetDesktopWindow;  //////////
 repeat
   //поиск корневого элемента
   IsRoot:=true;
   for j:=0 to n-1 do
     if (all[i].th32ParentProcessID=all[j].th32ProcessID) and (i<>j)
     then
      begin
       IsRoot:=false;
       break;
      end;
   //построение ветви
   if IsRoot
   then
    begin
     tvwProc.Items.AddObject(nil,ExtractFileName(all[i].szExeFile),@all[i]);
     tvwProc.Items[tvwProc.Items.Count-1].ImageIndex:=1;
     AddChild(i);
    end;
   inc(i);
  until i>=n;
 CloseHandle(SH);
 Form1.Caption:='Монитор - '+'Процессов: '+IntToStr(n)+
                 ', Потоков: '+IntToStr(thrCount);
end;

// осуществляет построение ветви дерева от корневого
// элемента до листьев
procedure TForm1.AddChild(k: integer);
var
  m,i: integer;
begin
  i:=0;
  m:=tvwProc.Items.Count;//добавляется всегда к последнему элементу
  pr:=all[k].th32ProcessID;//для AddWindow
  AddWindow(DT_hwnd);
  repeat
    if (all[i].th32ParentProcessID=all[k].th32ProcessID)and(i<>k) then begin
      tvwProc.Items.AddChildObject (tvwProc.Items[m-1],
                                    ExtractFileName(all[i].szExeFile),@all[i]);
      tvwProc.Items[tvwProc.Items.Count-1].ImageIndex:=1;
      AddChild(i);
    end;
    inc(i);
  until i>=n;
end;

// добавление дерева окон к д. процессов (перед вызовом
// указать ID процесса и Handle)
procedure TForm1.AddWindow(_hwnd: longint);
var
  m: integer;//  hw: longint;
begin
  m:=tvwProc.Items.Count-1;
  _hwnd:=GetWindow(_hWnd,GW_CHILD);
  while (_HWnd<>0) do begin
    thID:=GetWindowThreadProcessId(_hWnd,@prId);
    if prID=pr then begin       //если окно принадлежит процессу
      buflen:=GetWindowText(_HWnd,@buf,MaX_);
      if (buflen >0) then begin //если у окна есть имя
        inc(ihw);
        hw[ihw]:=_hwnd;
        tvwProc.Items.AddChildObject(tvwProc.Items[m],String(buf),@hw[ihw]);
        tvwProc.Items[tvwProc.Items.Count-1].ImageIndex:=2;
        AddWindow(_hwnd);
      end;
    end;
    _hwnd :=GetWindow(_hwnd, GW_HWNDNEXT);
  end;
end;

procedure TForm1.btnRecreateClick(Sender: TObject);
begin
  sgrInfo.Cells[1,0]:='';  sgrInfo.Cells[1,1]:='';  sgrInfo.Cells[1,2]:='';
  while tvwProc.items.Count<>0 do begin
    tvwProc.Items[0].Delete;
    Application.ProcessMessages;
  end;
  CreateProcessTree();
end;

procedure TForm1.btnPriorClick(Sender: TObject);
var
  priority: integer;
  HProc:Thandle;
  pr: byte;
begin
  HProc:=0;
  case cbPrior.ItemIndex of
    0:begin priority:=IDLE_PRIORITY_CLASS;    pr:=4; end;
    1:begin priority:=NORMAL_PRIORITY_CLASS;  pr:=8; end;
    2:begin priority:=HIGH_PRIORITY_CLASS;    pr:=13; end;
    3:begin priority:=REALTIME_PRIORITY_CLASS;pr:=24; end;
  end;

  HProc:=OpenProcess(PROCESS_SET_INFORMATION,false,ppe(tvwProc.Selected.Data)^.th32ProcessID);
  if not SetPriorityClass(HProc,priority) then begin
    ShowMessage('Невозможно изменить приоритет');
    ppe(tvwProc.Selected.Data)^.pcPriClassBase:=pr;
    tvwProcClick(self);
  end;
end;

// завершение процесса с использованием его идентификатора
procedure TForm1.btnTerminateClick(Sender: TObject);
var
  procId,ExCode : Cardinal;
  Hp : Thandle;   th: byte;
begin
  th:=ppe(tvwProc.Selected.data)^.cntThreads;
  Procid:=StrToInt64(edID.Text);
  Hp:=OpenProcess( PROCESS_TERMINATE,  //  флаг  доступа
     false,	// handle inheritance flag
     procid ); 	// process identifier
  if TerminateProcess(Hp,ExCode) then begin
    tvwProc.Selected.Delete;

    dec(n);
    dec(thrCount,th);
    Form1.Caption:='Монитор - '+'Процессов: '+IntToStr(n)+
                 ', Потоков: '+IntToStr(thrCount);
  end
  else
    ShowMessage('Невозможно завершить процесс');
  tvwProc.Repaint;
end;

procedure TForm1.tvwProcDblClick(Sender: TObject);
begin
  if not ((ppe(tvwProc.Selected.Data)^.cntThreads=0)or
  (ppe(tvwProc.Selected.Data)^.pcPriClassBase>32)) then begin
    edID.Text:=IntToStr(Ppe(tvwProc.Selected.Data)^.th32ProcessID);
    btnTerminate.Enabled:=true;
  end;
end;

procedure TForm1.tvwProcClick(Sender: TObject);
var
  cpos: TPoint;
  tr: TRect;
begin
  edID.Text:='';
  if (ppe(tvwProc.Selected.Data)^.cntThreads=0)or
     (ppe(tvwProc.Selected.Data)^.pcPriClassBase>32) then begin

    //ОКНО

    btnPrior.Enabled:=false;
    btnTerminate.Enabled:=false;
    if IsWindowVisible(longint(tvwProc.Selected.Data^)) then begin
      label1.Caption:='видимо';
      btnHideW.Enabled:=true;
      btnShowW.Enabled:=false;
    end
    else begin
      label1.Caption:='скрыто';
      btnShowW.Enabled:=true;
      btnHideW.Enabled:=false;
    end;
    sgrInfo.Cells[1,0]:='';  sgrInfo.Cells[1,1]:='';  sgrInfo.Cells[1,2]:='';
  end

  else begin
    //ПРОЦЕСС
    label1.Caption:='';
    btnHideW.Enabled:=false;
    btnShowW.Enabled:=false;
    btnPrior.Enabled:=true;
    btnTerminate.Enabled:=false;
    //
    sgrInfo.Cells[1,0]:=Ppe(tvwProc.Selected.Data)^.szExeFile;
    sgrInfo.Cells[1,1]:=IntToStr(Ppe(tvwProc.Selected.Data)^.pcPriClassBase);
    sgrInfo.Cells[1,2]:=IntToStr(Ppe(tvwProc.Selected.Data)^.cntThreads);
    case Ppe(tvwProc.Selected.Data)^.pcPriClassBase of
      4: cbPrior.ItemIndex:=0;//IDLE_PRIORITY_CLASS;
      8: cbPrior.ItemIndex:=1;//NORMAL_PRIORITY_CLASS;
      13:cbPrior.ItemIndex:=2;//HIGH_PRIORITY_CLASS;
      24:cbPrior.ItemIndex:=3;//REALTIME_PRIORITY_CLASS	;
    else
      cbPrior.ItemIndex:=-1;
    end;

  end;
end;
procedure TForm1.tvwProcKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (key=38)or(key=40) then tvwProcClick(Self);
end;


procedure TForm1.btnShowWClick(Sender: TObject);
begin
 ShowWindow(longint(tvwProc.Selected.Data^),SW_SHOW);
 btnHideW.Enabled:=true;
 btnShowW.Enabled:=false;
 label1.Caption:='видимо';
end;

procedure TForm1.btnHideWClick(Sender: TObject);
begin
  ShowWindow(longint(tvwProc.Selected.Data^),SW_HIDE);
  btnHideW.Enabled:=false;
  btnShowW.Enabled:=true;
  label1.Caption:='скрыто';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 CreateProcessTree();
 sgrInfo.ColWidths[1]:=500;
 sgrInfo.Cells[0,0]:='Имя';
 sgrInfo.Cells[0,1]:='Приоритет';
 sgrInfo.Cells[0,2]:='Потоков';
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
 i: integer;
begin
 all:=nil;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 tvwProc.FullExpand;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 tvwProc.FullCollapse;
end;

end.
