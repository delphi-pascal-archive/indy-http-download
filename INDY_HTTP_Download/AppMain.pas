unit AppMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, FileCtrl,
  Dialogs, IdHTTP, StdCtrls, StrUtils, DownloadThread, Buttons,
  ExtCtrls;

type
  TFormMain = class(TForm)
    OpnDlg: TOpenDialog;
    LblCurLine: TLabel;
    LblTotLine: TLabel;
    LblFicNull: TLabel;
    Label1: TLabel;
    LblCurrent: TLabel;
    LblTemps: TLabel;
    LblTot: TLabel;
    Max: TLabel;
    BtnBrowseDest: TButton;
    BtnOpenTxt: TButton;
    BtnOpenVar: TButton;
    BtnPause: TButton;
    EdtDest: TEdit;
    EdtNumMax: TEdit;
    Bevel1: TBevel;
    procedure BtnOpenVarClick(Sender: TObject);
    procedure BtnOpenTxtClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure BtnBrowseDestClick(Sender: TObject);
  private
    { Private declarations }
    fic: TextFile;                 //fichier utilisé (liste de downloads)
    ficName: String;               //nom du fichier à télécharger
    LstSrce, LstDest: TStringList; // fichier source et rep destination (décomposés)
    TabVar: array of TStringList; //listes de variables
    NbVar: integer;               //nbre de variables
    TabIndex: array of integer;  //indices courants de chaque liste de variables
    t0, t1: TDateTime;
    function GetFichier(const URL, FileName : string): Boolean;
    procedure TraiteLigne(vLigne: String); //traitement d'1 ligne (fichier de variables)
    procedure CreateLists;
    procedure FreeLists;
    procedure ClearLists;
    procedure InitTab;   //initialisation des tableaux
    procedure DelTab;    //libération des StringLists
    function GetNextTab: Boolean;  //prochain indice
    function MakeStr: String; //construction du nom de fichier à télécharger
    function MakeDest: String; //construction du nom de fichier destination
    procedure Tokenize(liste: TStringList; _str, _token: String);
    function VarStrToList(_var: String; _lst: TStringList): integer;
    function Formater(_val: String; _prec: integer): String;
    function GetMaxDL: integer; //nombre maxi de DL simulanés
  public
    { Public declarations }
    strBuff: String;
    procedure RefreshLabels;
    procedure ShowTime;
  end;

const
  repDLDef='C:\Downloads\';
  MaxDL= 4;  //nombre maximum de DL simultanés par défaut
  STR_NBNULS= 'Files not found: %d';
  STR_NUMLINE= 'Current file: %d';
  STR_NBDLLINE= 'Time total: %d';

var
  FormMain: TFormMain;
  DLTotal, DLCourants, nLigne, nbDLLigne, nbNuls: integer;
  Pause: Boolean;
  RepDL: String;

implementation

{$R *.dfm}

{------------------------------------------------------------------------------
 Objet: Initialisation
------------------------------------------------------------------------------}
procedure TFormMain.FormCreate(Sender: TObject);
begin
  DLTotal:=0;   //nb de DL effectués
  DLCourants:= 0;  //nb de DL en cours
  Pause:= False;   //en pause?
  BtnPause.Enabled:= False;
  EdtDest.Text:= RepDLDef; //rep destination de base (par défaut)
  RepDL:= EdtDest.Text;  //rep destination de base
end;

{------------------------------------------------------------------------------
 Objet: Traitement d'un fichier de Downloads avec variables
------------------------------------------------------------------------------}
procedure TFormMain.BtnOpenVarClick(Sender: TObject);
var
  ligne: String;
begin
  OpnDlg.Filter:= 'Text files|*.txt';
  if OpnDlg.Execute then
    begin
      //initialisation
      LblTemps.Caption:= 'Time total: ';
      t0:= GetTime;
      nLigne:= 0;
      nbDLLigne:= 0;
      nbNuls:= 0;
      AssignFile(fic, OpnDlg.FileName);
      Reset(fic);
      BtnPause.Enabled:= True;
      CreateLists;
      DLTotal:=0;
      RepDL:= EdtDest.Text;
      //Traitement du fichier
      while not eof(fic) do
      begin
        Readln(fic, ligne);
        Inc(nLigne);
        TraiteLigne(ligne);
      end;
      BtnPause.Enabled:= False;
      CloseFile(fic);
      FreeLists;
    end;
end;

{------------------------------------------------------------------------------
 Objet: Lancement d'un téléchargement
------------------------------------------------------------------------------}
function TFormMain.GetFichier(const URL, FileName : string): Boolean;
var
  thrd: THTTPDownloadThread;
  buff: String;
begin
  buff:= StringReplace(FileName, '/', '\', [rfReplaceAll]);
  thrd:= THTTPDownloadThread.Create(URL, buff, True);
  thrd.Resume;
end;

{------------------------------------------------------------------------------
 Objet: traite une ligne du fichier texte.
    Une ligne est formée de cette manière:
  RepDest;FicSrce   avec:
  RepDest= cst,i,cst,j... où cst sont des chaînes constantes et i,j les indices
           des variables utilisées;
  FicSrce= cst,Prec|v0|v1|...|vm:vn|...,cst...
  Prec est le nb de caractères (ex: '001' au lieu de '1') (mettre 0 pour des variables string).
  Des '|' séparent les valeurs possibles de cette variable, les ':' déterminant
  les limites d'une plage (entiers uniquement) - (ex: 1:20)
    Les chaînes de variables sont numérotées à partir de 0
------------------------------------------------------------------------------}
procedure TFormMain.TraiteLigne(vLigne: String);
var
  strSrce, strDest: String;
  p, i, vnbDL: integer;
begin
  ClearLists;
  DelTab;
  vnbDL:= 1;
  p:= Pos(';', vLigne); //séparateur "Dest;Source"
  if p>0 then
    begin
      // Interprétation de la ligne
      Tokenize(LstDest, MidStr(vLigne, 1, p-1), ','); //Rep de destination
      Tokenize(LstSrce, MidStr(vLigne, p+1, Length(vLigne)-p), ','); //Fichier source
      NbVar:= LstSrce.Count div 2; //nb de variables
      InitTab;    //initialisation des tableaux
      for i:=0 to NbVar-1 do
        begin
          VarStrToList(LstSrce[2*i+1], TabVar[i]); //analyse des variables
          vnbDL:= vnbDL * TabVar[i].Count; //nb de DL pour cette ligne
        end;
      nbDLLigne:= nbDLLigne + vnbDL; //nb total de DL en comptant cette ligne
      LblCurLine.Caption:= Format(STR_NUMLINE, [nLigne]);     //détails
      LblTotLine.Caption:= Format(STR_NBDLLINE, [nbDLLigne]);
      Application.ProcessMessages;

      // Lancement des downloads
      repeat
        while (DLCourants>=GetMaxDL) or Pause do
            Application.ProcessMessages;
        strSrce:= MakeStr;   //fichier source
        strDest:= MakeDest;  //fichier destination
        ShowTime;
        GetFichier(strSrce, strDest);
      until not GetNextTab;
    end;  // end if ';'
end;

{------------------------------------------------------------------------------
 Objet: renvoie une liste de chaînes à partir d'une chaîne et d'un séparateur
------------------------------------------------------------------------------}
procedure TFormMain.Tokenize(liste: TStringList; _str, _token: String);
var
  p: integer;
  buff: String;
begin
  liste.clear;
  buff:= _str;
  p:= Pos(_token, buff);
  while p>0 do
    begin
      liste.Add(MidStr(buff, 1, p-1)); //ajout à la liste
      buff:= MidStr(buff, p+1, Length(buff)-p);
      p:= Pos(_token, buff);
    end;
  liste.Add(buff);
end;

{------------------------------------------------------------------------------
 Objet: Construction d'une liste de valeurs à partir d'une expression de variable
        Prec|v0|v1|...|vm:vn|...
 Note : La précision est obligatoire et doit être <=0 pour des String. Si la
        précision est >0, les valeurs sont interprétées comme des entiers.
        la chaîne doit se terminer par une valeur (pas par le séparateur '|').
------------------------------------------------------------------------------}
function TFormMain.VarStrToList(_var: String; _lst: TStringList): integer;
var
  buff, valbuff: String;
  LstTemp: TStringList;
  deb, fin, prec, p, q: integer;
  i, j: integer;
begin
  LstTemp:= TStringList.Create;
  p:= Pos('|', _var); //début de la liste des valeurs
  prec:= StrToInt(MidStr(_var, 1, p-1)); //précision (nb de caractères pour formatage)
  buff:= MidStr(_var, p+1, Length(_var)-p); //liste des valeurs
  Tokenize(LstTemp, buff, '|'); //liste temporaire
  for i:=0 to LstTemp.Count - 1 do
    begin
      valbuff:= String(LstTemp[i]);
      q:= Pos(':', valbuff);
      if q>0 then
        begin   // plage de valeurs (=> entiers)
          deb:= StrToInt(MidStr(valbuff, 1, q-1)); //début de plage
          fin:= StrToInt(MidStr(valbuff, q+1, Length(valbuff)-q));  //fin de plage
          for j:=deb to fin do
            begin
              if prec>0 then
                  valbuff:= Formater(IntToStr(j), prec); //formatage
              _lst.Add(valbuff);
            end;  //end for j
        end
      else
        begin   // valeur unique
          if prec>0 then
              valbuff:= Formater(valbuff, prec);
          _lst.Add(valbuff);
        end;
    end;  //end for i
  LstTemp.Free;
  Result:= _lst.Count;
end;

{------------------------------------------------------------------------------
 Objet: Formate un nombre entier en le complétant par des '0' à gauche.
------------------------------------------------------------------------------}
function TFormMain.Formater(_val: String; _prec: integer): String;
var
  buff: String;
  v: integer;
begin
  v:= StrToInt(_val);
  buff:= Format('%' + IntToStr(_prec) + 'd', [v]);
  Result:= StringReplace(buff, ' ', '0', [rfReplaceAll]);
end;

{------------------------------------------------------------------------------
 Objet: Affichage.
------------------------------------------------------------------------------}
procedure TFormMain.RefreshLabels;
begin
  LblTot.Caption:= 'Downloads: ' + IntToStr(DLTotal);
  LblCurrent.Caption:= 'Current: ' + IntToStr(DLCourants);
  Application.ProcessMessages;
end;

{------------------------------------------------------------------------------
 Objet: Affichage du temps écoulé.
------------------------------------------------------------------------------}
procedure TFormMain.ShowTime;
begin
  t1:= GetTime;
  LblTemps.Caption:= 'Temps total: ' + TimeToStr(t1-t0);
end;

{------------------------------------------------------------------------------
 Objet: Création des listes Source et Destination.
------------------------------------------------------------------------------}
procedure TFormMain.CreateLists;
begin
  LstSrce:= TStringList.Create;
  LstDest:= TStringList.Create;
end;

{------------------------------------------------------------------------------
 Objet: Vide les listes.
------------------------------------------------------------------------------}
procedure TFormMain.ClearLists;
begin
  LstSrce.Clear;
  LstDest.Clear;
end;

{------------------------------------------------------------------------------
 Objet: Détruit les listes.
------------------------------------------------------------------------------}
procedure TFormMain.FreeLists;
begin
  LstSrce.Free;
  LstDest.Free;
end;

{------------------------------------------------------------------------------
 Objet: Initialisation des tableaux d'indices et de listes de variables
------------------------------------------------------------------------------}
procedure TFormMain.InitTab;
var
  i: integer;
begin
  SetLength(TabVar, NbVar);  //tableau de listes de variables
  SetLength(TabIndex, NbVar);   //tableau des indices courants de chaque liste
  for i:=0 to NbVar-1 do
    begin
      TabVar[i]:=TStringList.Create;
      TabIndex[i]:= 0;
    end;
end;

{------------------------------------------------------------------------------
 Objet: Libération des listes de variables
------------------------------------------------------------------------------}
procedure TFormMain.DelTab;
var
  i: integer;
begin
  for i:=0 to NbVar-1 do
    TabVar[i].Free;
end;

{------------------------------------------------------------------------------
 Objet: passe à l'indice suivant dans le tableau; renvoie False si tous les
        indices ont été passés
------------------------------------------------------------------------------}
function TFormMain.GetNextTab: Boolean;
var
  k: integer;
begin
  Result:= True;
  for k:= NbVar-1 downto 0 do
    begin
      if TabIndex[k]< TabVar[k].Count-1 then  //fin de liste?
        begin     //=> pas fin de liste
          Inc(TabIndex[k]);  // incrémentation de l'indice
          break;  //on sort!
        end
      else    // remise à 0 (début de liste) avant passage à l'indice inférieur (variable précédente)
        begin
          TabIndex[k]:=0;
          if k=0 then
            begin  // 1° variable
              Result:= False;
              break; //on sort!
            end;
        end;  //end if tab[k]< max
    end;
end;

{------------------------------------------------------------------------------
 Objet: Construit et renvoie le nom complet du fichier source et affecte la
        variable ficName (utilisée dans MakeDest)
------------------------------------------------------------------------------}
function TFormMain.MakeStr: String;
var
  buff: String;
  i, p: integer;
begin
  buff:= '';
  for i:=0 to LstSrce.Count-1 do
    begin
      if not Odd(i) then  //valeur constante
          buff:= buff + LstSrce[i]
      else         //variable
          buff:= buff + TabVar[(i-1) div 2].Strings[TabIndex[(i-1) div 2]];
    end;
  p:= Length(buff);
  while MidStr(buff, p, 1)<>'/' do Dec(p);
  ficName:= MidStr(buff, p+1, Length(buff)-p); //nom du fichier à télécharger
  Result:= buff;
end;

{------------------------------------------------------------------------------
 Objet: Construit et renvoie le nom complet du fichier destination
------------------------------------------------------------------------------}
function TFormMain.MakeDest: String;
var
  i, numVar: integer;
  buff: String;
begin
  buff:= RepDL;
  for i:=0 to LstDest.Count-1 do
    begin
      if not Odd(i) then   //valeur constante
          buff:= buff + LstDest[i]
      else      //numéro d'une variable
        begin
          numVar:= StrToInt(LstDest[i]);
          buff:= buff + TabVar[numVar].Strings[TabIndex[numVar]];
        end;
    end;
  buff:= buff + ficName;
  Result:= buff;
end;

{------------------------------------------------------------------------------
 Objet: Ouvre un fichier à plat (CSV)
        les ligne de ce fichier sont construites comme suit:
        Source;Subdir;newFicName avec Source= url complet du fichier source,
        Subdir= sous-rep destination (dans le rep destination de base),
        newFicName= nom du fichier destination
------------------------------------------------------------------------------}
procedure TFormMain.BtnOpenTxtClick(Sender: TObject);
var
  buff, _url, _dest: String;
  _lst: TStringList;
begin
  OpnDlg.Filter:= 'Fichier CSV|*.csv';
  if OpnDlg.Execute then
    begin
      //Initialisation
      LblTemps.Caption:= 'Time total: ';
      t0:= GetTime;
      DLTotal:=0;
      AssignFile(fic, OpnDlg.FileName);
      Reset(fic);
      BtnPause.Enabled:= True;
      _lst:= TStringList.Create;
      DLTotal:=0;
      RepDL:= EdtDest.Text;
      //Traitement du fichier
      while not eof(fic) do
      begin
        Readln(fic, buff);
        Tokenize(_lst, buff, ';');
        //Construction des noms de fichiers source et destination
        _url:= _lst.Strings[0];
        _dest:= StringReplace(_lst.Strings[1], '/', '\', [rfreplaceall]);
        if MidStr(_dest, Length(_dest), 1)<>'\' then
            _dest:= _dest + '\';
        _dest:= repDL + _dest + _lst.Strings[2];
        //Download
        while (DLCourants>=GetMaxDL) or Pause do
            Application.ProcessMessages;
        ShowTime;
        GetFichier(_url, _dest);
        _lst.Clear;
      end;
      CloseFile(fic);
      _lst.Free;
      BtnPause.Enabled:= False;
    end;  // end if OpnDlg
end;

{------------------------------------------------------------------------------
 Objet: Met en pause ou reprend le download. En pause, les threads en cours
        se terminent normalement mais aucun nouveau thread n'est lancé.
------------------------------------------------------------------------------}
procedure TFormMain.BtnPauseClick(Sender: TObject);
begin
  Pause:= not Pause;
  if Pause then
      BtnPause.Caption:= 'Continue'
  else
      BtnPause.Caption:= 'Pause';
end;

{------------------------------------------------------------------------------
 Objet: Sélection d'un répertoire
------------------------------------------------------------------------------}
procedure TFormMain.BtnBrowseDestClick(Sender: TObject);
var
  buff: String;
  options: TSelectDirOpts;
begin
  buff:= EdtDest.Text;
  if SelectDirectory(buff, options,0) then
    begin
      EdtDest.Text:= buff;
    end;
end;

{------------------------------------------------------------------------------
 Objet: Renvoie le nb maxi de downloads simultanés
------------------------------------------------------------------------------}
function TFormMain.GetMaxDL: integer;
begin
  try
    Result:= StrToInt(EdtNumMax.Text);
  except
    on EConvertError do
      Result:= MaxDL;
  end;
end;

end.
