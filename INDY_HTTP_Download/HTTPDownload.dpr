program HTTPDownload;

uses
  Forms,
  AppMain in 'AppMain.pas' {FormMain},
  DownloadThread in 'DownloadThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
