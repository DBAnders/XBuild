program XBuild;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  Process,
  Crt
  ;

type
  { TMyApp }
  TMyApp = class(TCustomApplication)
  protected
      procedure DoRun; override;

    public
      constructor Create(TheOwner: TComponent); override;
      destructor Destroy; override;

    private
      sFile : String;
      sPara : String;
      sExec : String;
      lParam : TStringList;
      iError : Integer;
      procedure WriteErr(sMsg:String);
      procedure WriteWait(sMsg:String);
      procedure WriteVal(sName,sVal:String; col:Integer);
      procedure WriteArray(sName,sVal:String; I,col:Integer);
      procedure PrintText(iSel:Integer);
      procedure MainProg;
      function LoadConfig:Boolean;
  end;

var
  Application: TMyApp;

const
    MSG_WELCOME = 0;
    MSG_EXECUTE = 1;
    MSG_USAGE   = 2;

{ TMyApp }
//------------------------------------------------------------------------------
procedure TMyApp.WriteErr(sMsg:String);
begin
    TextColor(13);
    WriteLn('<ERROR> '+ sMsg);
    TextColor(7);
end;

//------------------------------------------------------------------------------
procedure TMyApp.WriteWait(sMsg:String);
begin
    TextColor(14);
    WriteLn('<WAIT> '+ sMsg);
    TextColor(7);
    ReadLn;
    WriteLn('<DONE>');
end;

//------------------------------------------------------------------------------
procedure TMyApp.WriteVal(sName,sVal:String; col:Integer);
begin
    TextColor(7);
    Write(sName);
    TextColor(3);
    Write('=');
    TextColor(col);
    WriteLn(sVal);
end;

//------------------------------------------------------------------------------
procedure TMyApp.WriteArray(sName,sVal:String; I,col:Integer);
begin
    TextColor(7);
    Write(sName);
    TextColor(3);
    Write('[');
    TextColor(12);
    Write(IntToStr(I));
    TextColor(3);
    Write(']=');
    TextColor(col);
    WriteLn(sVal);
end;

//------------------------------------------------------------------------------
// Execute Complier or Flash Tool
//------------------------------------------------------------------------------
procedure TMyApp.MainProg;
var
    AProcess : TProcess;
    I : Integer;
    S : String;
begin
    WriteVal('Execute', sExec, 10);
    WriteVal('ParamCount', IntToStr(lParam.Count), 12);
    if lParam.Count <= 0 then
    begin
        WriteErr('not enough parameters...');
        exit;
    end;

    Aprocess := TProcess.Create(nil);
    AProcess.CurrentDirectory := ExtractFilePath(sExec);
    AProcess.Executable := sExec;

    for I := 1 to lParam.Count do
    begin
        Aprocess.Parameters.Add(lParam[I-1]);
    end;

    if Length(sPara) > 2 then
    begin
        S := sPara;
        Aprocess.Parameters.Add(S);
        WriteVal('AddParam', S, 14);
    end;

    Aprocess.options := AProcess.Options + [poWaitOnExit];
                      //poUsePipes]; //poWaitOnExit, poUsePipes];
    PrintText(MSG_EXECUTE);
    AProcess.Execute;
    iError := AProcess.ExitCode;
    AProcess.Free;
end;

//------------------------------------------------------------------------------
// LOAD XBuilder Script File
//------------------------------------------------------------------------------
function TMyApp.LoadConfig:Boolean;
var
    F: Text;
    S : String;
    I : Integer;
begin
    WriteLn('XBuildScript="'+ sFile+'"');
    AssignFile(F, sFile);
    {$I-}
    Reset(F);
    {$I+}
    if IOresult <> 0 then
    begin
        WriteErr('Can''''t open file...');
        LoadConfig := False;
        exit;
    end;

    ReadLn(F, S);
    sExec := S;
//    sExec := 'D:\Arduino\arduino-1.8.9\arduino-builder-0.exe';
//    sExec := 'ParaCheck.exe';
    WriteLn('Builder="'+ sExec+'"');
    lParam := TStringList.Create;
    I := 0;
    while not EOF(F) do
    begin
        Inc(I);
        ReadLn(F, S);
        if Length(S) >= 1 then
        begin
            lParam.Add(S);
            WriteArray('Param', S, I-1, 10);
        end;
    end;
    CloseFile(F);
    LoadConfig := True;
end;

//------------------------------------------------------------------------------
// PRINT MESSAGE FUNCTION
//------------------------------------------------------------------------------
procedure TMyApp.PrintText(iSel:Integer);
begin
    WriteLn;
    TextColor(3);
    WriteLn('-----------------------------------------------------------------');
    TextColor(7);
    case iSel of
        MSG_WELCOME:
        begin
            WriteLn(' XBuild - Arduino Builder Console - v1.0.19.07.12');
            WriteLn(' Build Tool for INO Editor - Copyright (C) by M. Anders');
        end;

        MSG_EXECUTE:
        begin
            WriteLn(' Start "arduino-builder.exe"...');
        end;

        MSG_USAGE:
        begin
            TextColor(11);
            WriteLn(' USAGE: XBuild <builder_script> <options>');
            WriteLn('  <builder_script>  Builder script for compile or flash');
            WriteLn('  <options>         -w: WaitFlag = True');

        end
    end;
    TextColor(3);
    WriteLn('-----------------------------------------------------------------');
    TextColor(7);
end;

//------------------------------------------------------------------------------
// MAIN LOOP (Run only 1)
//------------------------------------------------------------------------------
procedure TMyApp.DoRun;
var
    bWait : Boolean;
begin
    PrintText(MSG_WELCOME);

    sFile := '';
    sPara := '';
    bWait := False;

    if ParamCount >= 1 then
    begin
        sFile := ParamStr(1) + '.xbs';

        if ParamCount >= 2 then
        begin
            sPara := ParamStr(2);
            if sPara = '-w' then
                bWait := True;
            sPara := '';
        end;

        if LoadConfig then
        begin
            MainProg;
        end;
    end
    else
    begin
        PrintText(MSG_USAGE);
    end;

    if bWait then
    begin
        WriteWait('Please press ENTER...');
    end;

    if (iError <> 0) then
    begin
        WriteLn('ErrorCode: '+ IntToStr(iError));
        Terminate(iError)
    end
    else
        Terminate
end;

//------------------------------------------------------------------------------
// CONSTRUCTOR / INIT
//------------------------------------------------------------------------------
constructor TMyApp.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

//------------------------------------------------------------------------------
// DESCTRUCTOR / DEINIT
//------------------------------------------------------------------------------
destructor TMyApp.Destroy;
begin
  inherited Destroy;
end;

//------------------------------------------------------------------------------
// MAIN PROGRAM
//------------------------------------------------------------------------------
begin
  Application := TMyApp.Create(nil);
  Application.Title :='XBuild.INO.Editor';
  Application.Run;
  Application.Free;
end.

