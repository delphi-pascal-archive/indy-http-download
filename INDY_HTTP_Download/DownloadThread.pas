unit DownloadThread;

interface

uses Windows, Classes, SysUtils, IdHTTP, StrUtils;

type
  THTTPDownloadThread = class(TThread)
  private
    ficSource:String;
    repDest: String;
    IdHTTP: TIdHTTP;
    function TailleFichier(fichier: string): longint;
  public
    constructor Create(Source,Dest: String; CreateSuspended:boolean);
    destructor Destroy; override;
  protected
    procedure Execute; override;
  end;

implementation

uses
  AppMain;

{------------------------------------------------------------------------------
------------------------------------------------------------------------------}
constructor THTTPDownloadThread.Create(Source,Dest: String; CreateSuspended:boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate:=True; // libération automatique de la mémoire
  Priority:=tpNormal;
  ficSource:= Source;
  repDest:= Dest;
  IdHTTP:= TIdHTTP.Create(nil);
  Inc(DLTotal);
  Inc(DLCourants);
  FormMain.RefreshLabels;
end;

{------------------------------------------------------------------------------
------------------------------------------------------------------------------}
destructor THTTPDownloadThread.Destroy;
begin
  if TailleFichier(Repdest)<1024 then // fichier <1ko
    begin
      DeleteFile(Repdest);
      Inc(nbNuls);
      FormMain.LblFicNull.Caption:= Format(STR_NBNULS, [nbNuls]);
    end;
  Dec(DLCourants);
  FormMain.RefreshLabels;
  FormMain.ShowTime;
  inherited;
end;

{------------------------------------------------------------------------------
------------------------------------------------------------------------------}
procedure THTTPDownloadThread.Execute;
var
  idHttp: TIdHTTP;
  Stream: TFileStream;
begin
  ForceDirectories(ExtractFilePath(Repdest));
  Stream := TFileStream.Create(Repdest, fmCreate or fmShareExclusive);
  try
    idHttp := TIdHTTP.Create(nil);
    try
      idHttp.Get(ficSource, Stream);
    finally
      idHttp.Free;
    end;
  finally
    Stream.Free;
  end;
end;

{------------------------------------------------------------------------------
  fonction renvoyant la taille du fichier 'fichier' en Octets
------------------------------------------------------------------------------}
function THTTPDownloadThread.TailleFichier(fichier: string): longint;
var SearchRec:TSearchRec;
    Resultat:integer;
begin
  Result:=0;
  Resultat:=FindFirst(fichier, FaAnyFile, SearchRec);
  if Resultat=0 then Result:=SearchRec.Size;
  FindClose(SearchRec);
end;

end.


