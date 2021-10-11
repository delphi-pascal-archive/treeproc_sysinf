unit SysInfoU;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, Buttons, ImgList, Commctrl, ShellAPI, Menus, ExtCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet2: TTabSheet;
    TabSheet1: TTabSheet;
    ListView1: TListView;
    StatusBar1: TStatusBar;
    ListView2: TListView;
    ImageList1: TImageList;
    PopupMenu1: TPopupMenu;
    Details1: TMenuItem;
    KillProcess1: TMenuItem;
    RefreshList1: TMenuItem;
    PopupMenu2: TPopupMenu;
    CloseWindow1: TMenuItem;
    RefreshList2: TMenuItem;
    StatusBar2: TStatusBar;
    Timer1: TTimer;
    procedure PageControl1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Details1Click(Sender: TObject);
    procedure KillProcess1Click(Sender: TObject);
    procedure RefreshList1Click(Sender: TObject);
    procedure CloseWindow1Click(Sender: TObject);
    procedure RefreshList2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

uses
  TlHelp32, AdditU;

procedure ListProcesses;
var
 hSnapShot: THandle;
 lppe: TProcessEntry32;
 hIcon: THandle;
 Count: Integer;

 procedure _FillList;
  begin
    with Form1.ListView1.Items.Add, lppe do
     begin
      hIcon:= ExtractIcon(hInstance, lppe.szExeFile, 0);
      if hIcon = 0 then
        hIcon:= LoadImage(0, IDI_WINLOGO, IMAGE_ICON, LR_DEFAULTSIZE,
         LR_DEFAULTSIZE, LR_DEFAULTSIZE or LR_DEFAULTCOLOR or LR_SHARED);
      ImageIndex:= ImageList_AddIcon(Form1.ImageList1.Handle, hIcon);
      Caption:= ExtractFileName(szExeFile);
      SubItems.Add(Format('$%x', [Th32ProcessID]));
      SubItems.Add(Format('$%x', [Th32ParentProcessID]));
      case pcPriClassBase of
          4: SubItems.Add(Format('%d (Idle)', [pcPriClassBase]));
          8: SubItems.Add(Format('%d (Norm)', [pcPriClassBase]));
         13: SubItems.Add(Format('%d (High)', [pcPriClassBase]));
         24: SubItems.Add(Format('%d (Real)', [pcPriClassBase]));
      else
       SubItems.Add(Format('%d', [pcPriClassBase]));
     end;
     SubItems.Add(Format('%d', [cntThreads]));
     SubItems.Add(Format('%d', [cntUsage]));
     SubItems.Add(szExeFile);
    end;
   inc(Count);
  end;

begin
 hSnapShot:= CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);
 if hSnapShot<>INVALID_HANDLE_VALUE then
  begin
   Form1.ListView1.Items.Clear;
   lppe.dwSize:= SizeOf(lppe);
   Count:= 0;
   if Process32First(hSnapShot, lppe) then _FillList;
   while Process32Next(hSnapShot, lppe) do _FillList;
   Form1.StatusBar1.Panels[1].Text:= 'Всего: ' + IntToStr(Count);
   CloseHandle(hSnapShot);
  end
   else
    MessageBox(Form1.Handle, 'Internal error', 'Error', MB_OK or MB_ICONERROR);
end;

procedure ListWindows;

 function EnumWindowsProc(hWnd: THandle; lParam: Integer): Boolean; stdcall;
 var
  Text,
  PName: string;
  hIcon: THandle;
  lpdwPID: PDWORD;
  i: Integer;
 begin
  New(lpdwPID);
  GetWindowThreadProcessID(hWnd, lpdwPID);
  SetLength(Text, 255);
  if GetWindowText(hWnd, PChar(Text), 255)<>0 then
  with Form1.ListView2.Items.Add, Form1.ListView1 do
   begin
    hIcon:= GetClassLong(hWnd, GCL_HICON);
    ImageIndex:= ImageList_AddIcon(Form1.ImageList1.Handle, hIcon);
    for i:= 0 to Items.Count-1 do
     if Cardinal(StrToInt(Items[i].SubItems[0]))=lpdwPID^
      then
       PName:= Items[i].Caption;
       Caption:= Text;
       SubItems.Add(Format('%d', [hWnd]));
       SubItems.Add(Format('$%x', [lpdwPID^]));
       SubItems.Add(PName);
       Dispose(lpdwPID);
    end;
  Result:= true;
 end;

begin
 Form1.ListView2.Items.Clear;
 EnumWindows(@EnumWindowsProc, 0);
end;

procedure ListModules(OwnerID: Cardinal);
var
 hSnapShot: THandle;
 lpme: TModuleEntry32;

 procedure _FillList;
 begin
  with Form2.ListView1.Items.Add, lpme do
   begin
    Caption:= ExtractFileName(szModule);
    SubItems.Add(Format('%d', [modBaseSize]));
    SubItems.Add(Format('$%p', [modBaseAddr]));
    SubItems.Add(Format('%d', [ProccntUsage]));
    SubItems.Add(Format('%d', [GlblcntUsage]));
    SubItems.Add(szExePath);
   end;
 end;

begin
 hSnapShot:= CreateToolHelp32Snapshot(TH32CS_SNAPMODULE, OwnerID);
 if hSnapShot<>INVALID_HANDLE_VALUE then
  begin
   Form2.ListView1.Items.Clear;
   lpme.dwSize:= SizeOf(lpme);
   if Module32First(hSnapShot, lpme) then _FillList;
   while Module32Next(hSnapShot, lpme) do _FillList;
   CloseHandle(hSnapShot);
  end
 else
  MessageBox(Form1.Handle, 'Internal error', 'Error', MB_OK or MB_ICONERROR);
end;

procedure ListThreads(OwnerID: Cardinal);
var
 hSnapShot: THandle;
 lpte: TThreadEntry32;

 procedure _FillList;
 begin
  if lpte.Th32OwnerProcessID = Cardinal(StrToInt(Form1.ListView1.Selected.SubItems[0])) then
  with Form2.ListView2.Items.Add, lpte do
   begin
    Caption:= Format('$%x', [Th32ThreadID]);
     case TpBasePri of
       4: SubItems.Add(Format('%d (Idle)', [TpBasePri]));
       8: SubItems.Add(Format('%d (Norm)', [TpBasePri]));
      13: SubItems.Add(Format('%d (High)', [TpBasePri]));
      24: SubItems.Add(Format('%d (Real)', [TpBasePri]));
     else
      SubItems.Add(Format('%d', [TpBasePri]));
     end;
     case TpDeltaPri of
      -15: SubItems.Add(Format('%d (Idle)', [TpDeltaPri]));
       -2: SubItems.Add(Format('%d (Lowest)', [TpDeltaPri]));
       -1: SubItems.Add(Format('%d (Low)', [TpDeltaPri]));
        0: SubItems.Add(Format('%d (Normal)', [TpDeltaPri]));
        1: SubItems.Add(Format('%d (High)', [TpDeltaPri]));
        2: SubItems.Add(Format('%d (Highest)', [TpDeltaPri]));
       15: SubItems.Add(Format('%d (Time Critical)', [TpDeltaPri]));
     else
      SubItems.Add(Format('%d', [TpDeltaPri]));
     end;
    SubItems.Add(Format('%d', [cntUsage]));
   end;
 end;

begin
 hSnapShot:= CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, OwnerID);
 if hSnapShot<>INVALID_HANDLE_VALUE then
  begin
   Form2.ListView2.Items.Clear;
   lpte.dwSize:= SizeOf(lpte);
   if Thread32First(hSnapShot, lpte) then _FillList;
   while Thread32Next(hSnapShot, lpte) do _FillList;
   CloseHandle(hSnapShot);
  end
  else
   MessageBox(Form1.Handle, 'Internal error', 'Error', MB_OK or MB_ICONERROR);
end;

procedure ListHeaps(OwnerID: Cardinal);
var
 hSnapShot: THandle;
 lphl: THeapList32;
 lphe: THeapEntry32;

 procedure _FillList;
 begin
  if Heap32First(lphe, lphl.Th32ProcessID, lphl.Th32HeapID) then
   repeat
     with Form2.ListView3.Items.Add, lphe do
      begin
       Caption:= Format('$%x', [Th32HeapID]);
       SubItems.Add(Format('%d', [dwBlockSize]));
       SubItems.Add(Format('$%x', [dwAddress]));
       case dwFlags of
         LF32_FIXED: SubItems.Add('Fixed');
         LF32_FREE: SubItems.Add('Free');
         LF32_MOVEABLE: SubItems.Add('Moveable')
       else SubItems.Add('Unknown');
       end;
      end
   until not Heap32Next(lphe);
 end;

begin
 try
  Form1.Caption:='SysInfo: PROCESSING... PLEASE WAIT';
  hSnapShot:= CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, OwnerID);
  if hSnapShot<>INVALID_HANDLE_VALUE then
   begin
    Form2.ListView3.Items.Clear;
    lphl.dwSize:= SizeOf(lphl);
    lphe.dwSize:= SizeOf(lphe);
    if Heap32ListFirst(hSnapShot, lphl) then _FillList;
    while Heap32ListNext(hSnapShot, lphl) do _FillList;
    CloseHandle(hSnapShot);
   end
  else
   MessageBox(Form1.Handle, 'Internal error', 'Error', MB_OK or MB_ICONERROR);
 finally
  Form1.Caption:= 'SysInfo';
 end;
end;

procedure ListThreadWindows;
var
 i:integer;

 function EnumThreadWindowsProc(hWnd: THandle; lParam: Integer): Boolean; stdcall;
 var
  Text: string;
  hIcon: THandle;
 begin
  SetLength(Text, 255);
  if GetWindowText(hWnd, PChar(Text), 255)<>0 then
  with Form2.ListView4.Items.Add do
   begin
    hIcon:= GetClassLong(hWnd, GCL_HICON);
    ImageIndex:= ImageList_AddIcon(Form1.ImageList1.Handle, hIcon);
    Caption:= Text;
    SubItems.Add(Format('%d', [hWnd]));
//    SubItems.Add()
   end;
  Result:= true;
 end;

begin
 Form2.ListView4.Items.Clear;
 for i:=0 to Form2.ListView2.Items.Count-1 do
  EnumThreadWindows(Cardinal(StrToInt(Form2.ListView2.Items[i].Caption)),
                                              @EnumThreadWindowsProc, 0);
end;

{---------------------------EVENT HANDLERS--------------------------------}

procedure TForm1.PageControl1Change(Sender: TObject);
begin
 //ListProcesses;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 ListProcesses;
 ListWindows;
 Application.Title:='Sys Info';
end;

procedure TForm1.ListView1Click(Sender: TObject);
begin
 with (Sender as TListView) do
  if Selected<>nil
  then StatusBar1.Panels[0].Text:=Selected.SubItems[5]
  else StatusBar1.Panels[0].Text:='';
end;

procedure TForm1.ListView1DblClick(Sender: TObject);
begin
 Details1Click(self);
end;

procedure TForm1.ListView1KeyUp(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 if flag=true then flag:=false
 else
  begin
   if Key=13 then ListView1DblClick(ListView1);
   if Key<>0 then ListView1Click(ListView1);
  end;
end;

procedure TForm1.Details1Click(Sender: TObject);
begin
 with ListView1, Form2 do
  if Selected<>nil then
   begin
    ListModules(StrToInt(Selected.SubItems[0]));
    ListThreads(StrToInt(Selected.SubItems[0]));
    ListHeaps(StrToInt(Selected.SubItems[0]));
    ListThreadWindows;
    Caption:='Details for ' + Selected.Caption;
    Show;
   end
  else
   MessageBox(Handle, 'Select a process to see details.',
                             'Information', MB_OK or MB_ICONINFORMATION);
end;

procedure TForm1.KillProcess1Click(Sender: TObject);
var
 hProcess: THandle;
 S: string;
 ID: Cardinal;
begin
 if ListView1.Selected<>nil then
  begin
   S:=ListView1.Selected.Caption;
   ID:=StrToInt(ListView1.Selected.SubItems[0]);
   hProcess:=OpenProcess(PROCESS_ALL_ACCESS, false, ID);
   if hProcess<>INVALID_HANDLE_VALUE then
    begin
     if not TerminateProcess(hProcess, 0)
     then MessageBox(0, PChar('Unable to kill process: ' + S),
                                       'Error', MB_ICONWARNING or MB_OK);
     CloseHandle(hProcess);
     Sleep(500);
     ListProcesses;
    end;
  end
  else
   MessageBox(Handle, 'Select a process to be killed.', 'Information',
                                            MB_OK or MB_ICONINFORMATION);
end;

procedure TForm1.RefreshList1Click(Sender: TObject);
begin
 ListProcesses;
end;

procedure TForm1.CloseWindow1Click(Sender: TObject);
begin
 if ListView2.Selected <> nil then
  begin
   PostMessage(StrToInt(ListView2.Selected.SubItems[0]), WM_CLOSE, 0, 0);
   Sleep(500);
   ListWindows;
  end
 else
  MessageBox(Handle, 'Select a window to be closed.', 'Information',
                                            MB_OK or MB_ICONINFORMATION);
end;

procedure TForm1.RefreshList2Click(Sender: TObject);
begin
 ListWindows;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
 MS: TMemoryStatus;
 s,ss: string;
begin
 GlobalMemoryStatus(MS);
 ss:='всего оперативной памяти   - '+FormatFloat('  #,###" MB"', MS.dwTotalPhys/1024/1000);
 s:=Format('%d %%', [MS.dwMemoryLoad]);
 StatusBar2.Panels[0].Text:='Загруженность памяти: '+s+', ('+ss+')';
end;

procedure TForm1.StatusBar1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
 if StatusBar1.Panels[0].Text<>''
 then StatusBar1.Hint:=StatusBar1.Panels[0].Text
 else StatusBar1.Hint:='';
end;

end.
