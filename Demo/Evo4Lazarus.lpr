program Evo4Lazarus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uEvo4Lazarus, EvolutionAPI;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
		  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TfrmEvo4Lazarus, frmEvo4Lazarus);
  Application.Run;
end.

