/************************************************
* TVD Encryption: Main form module              *
* By Ravil Mussabayev                           *
* ravmus@gmail.com                              *
************************************************/
unit UnitMain;

interface

uses
  EncryptLib, EncryptMath, System.TimeSpan, System.Diagnostics,
  //--------------------------------------------------------------------------------------
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.ExtCtrls,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList,
  Vcl.RibbonLunaStyleActnCtrls, Vcl.ActnMan, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.XPStyleActnCtrls;

type
  TMainForm = class(TForm)
    ActionManager1: TActionManager;
    ImageList1: TImageList;
    ActionGenerateKeys: TAction;
    ActionImportKey: TAction;
    ActionKeyInfo: TAction;
    ActionFileEncrypt: TAction;
    GroupBox1: TGroupBox;
    Edit_K: TLabeledEdit;
    MemoResult: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    ListBox_D: TListBox;
    BitBtn2: TBitBtn;
    ActionSaveToFile: TAction;
    SaveDialog: TSaveDialog;
    ActionClear: TAction;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    OpenDialog: TOpenDialog;
    GroupBox2: TGroupBox;
    Bevel1: TBevel;
    ProgressBar: TProgressBar;
    BitBtn5: TBitBtn;
    EditInputFile: TButtonedEdit;
    Label3: TLabel;
    EditOutputFile: TButtonedEdit;
    Label4: TLabel;
    ImageList2: TImageList;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    ActionFileDecrypt: TAction;
    StatusBar: TStatusBar;
    Panel1: TPanel;
    Label5: TLabel;
    ChBoxText: TCheckBox;
    procedure ActionGenerateKeysExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox_DDblClick(Sender: TObject);
    procedure ActionSaveToFileExecute(Sender: TObject);
    procedure ActionClearExecute(Sender: TObject);
    procedure ActionKeyInfoExecute(Sender: TObject);
    procedure EditInputFileLeftButtonClick(Sender: TObject);
    procedure EditOutputFileLeftButtonClick(Sender: TObject);
    procedure ActionImportKeyExecute(Sender: TObject);
    procedure ActionFileEncryptExecute(Sender: TObject);
    procedure ActionFileDecryptExecute(Sender: TObject);
    procedure EditInputFileRightButtonClick(Sender: TObject);
    procedure EditOutputFileRightButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure ClearAll;
  public
    { Public declarations }
    Encrypt: TEncrypt;
  end;

var
  MainForm: TMainForm;
  SecretKeyList: TStringList;
  k: Int64;

implementation

{$R *.dfm}

procedure TMainForm.ActionSaveToFileExecute(Sender: TObject);
var i: Integer;
    d: Int64;
    f: File of Int64;
begin
  if SecretKeyList.Count = 0 then begin
    MessageDlg('You have to choose at least one key D', mtError, [mbOK], 0);
    Exit;
  end;
  if SaveDialog.Execute then begin
    AssignFile(f, SaveDialog.FileName);
    Rewrite(f);
    Write(f, k);
    for i := 0 to SecretKeyList.Count - 1 do begin
      d := StrToInt64(SecretKeyList.Strings[i]);
      Write(f, d);
    end;
    CloseFile(f);
    ClearAll;
  end;
end;

procedure TMainForm.ClearAll;
begin
  SecretKeyList.Clear;
  Edit_K.Clear;
  ListBox_D.Clear;
  MemoResult.Clear;
end;

procedure TMainForm.EditInputFileLeftButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    EditInputFile.Text := OpenDialog.FileName;
end;

procedure TMainForm.EditInputFileRightButtonClick(Sender: TObject);
begin
  EditOutputFile.Text := EditInputFile.Text;
end;

procedure TMainForm.EditOutputFileLeftButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    EditOutputFile.Text := OpenDialog.FileName;
end;

procedure TMainForm.EditOutputFileRightButtonClick(Sender: TObject);
begin
  EditInputFile.Text := EditOutputFile.Text;
end;

procedure TMainForm.ActionClearExecute(Sender: TObject);
begin
  ClearAll;
end;

procedure TMainForm.ActionKeyInfoExecute(Sender: TObject);
var i: Integer;
    d: Int64;
    f: File of Int64;
    result: String;
begin
  if OpenDialog.Execute then begin
    AssignFile(f, OpenDialog.FileName);
    Reset(f);
    Read(f, k);
    result := 'k = ' + IntToStr(k) + #10#13;
    i := 0;
    while not EOF(f) do begin
      Read(f, d);
      Inc(i);
      result := Concat(result, 'd' + IntToStr(i) + ' = ', IntToStr(d), #10#13);
    end;
    CloseFile(f);
    MessageDlg(result, mtInformation, [mbOk], 0);
  end;
end;

procedure TMainForm.ActionFileDecryptExecute(Sender: TObject);
var FileStream, DecodedStream: TMemoryStream;
    Stopwatch: TStopwatch;
    Elapsed: TTimeSpan;
    ZeroByte: Boolean;
begin
  if not Encrypt.imported then begin
    MessageDlg('You have to import an existing key.', mtError, [mbOk], 0);
    Exit;
  end;

  FileStream := TMemoryStream.Create;
  if EditInputFile.Text[length(EditInputFile.Text)] = '1' then ZeroByte := True
                                                          else ZeroByte := False;
  try
    FileStream.LoadFromFile(EditInputFile.Text);
  except
    on EO: EFOpenError do begin
      MessageDlg('You have to choose an input file.', mtError, [mbOk], 0);
      Exit;
    end;
  end;
  try
    Stopwatch := TStopwatch.StartNew;
    DecodedStream := Encrypt.Decode(FileStream, @ProgressBar, ZeroByte);
    Elapsed := Stopwatch.Elapsed;
    StatusBar.SimpleText := 'Elapsed time: ' +
                              FloatToStr(Elapsed.TotalMilliseconds) + ' mills' +
                              ' or ' + FloatToStr(DecodedStream.Size /
                              Elapsed.TotalSeconds) + ' bytes per sec';
    try
      DecodedStream.SaveToFile(EditOutputFile.Text);
    except
      on EO: EFCreateError do begin
        MessageDlg('You have to choose an output file.', mtError, [mbOk], 0);
        Exit;
      end;
    end;
    DecodedStream.Free;
  finally
    FileStream.Free;
  end;
end;

procedure TMainForm.ActionFileEncryptExecute(Sender: TObject);
var FileStream, EncodedStream: TMemoryStream;
    Stopwatch: TStopwatch;
    Elapsed: TTimeSpan;
    f: TextFile;
    ZeroByte: Boolean;
    FileName: string;
begin
  if not Encrypt.imported then begin
    MessageDlg('You have to import an existing key.', mtError, [mbOk], 0);
    Exit;
  end;

  FileStream := TMemoryStream.Create;
  if ChBoxText.Checked then begin
    AssignFile(f, EditOutputFile.Text + '.hr');
    Rewrite(f);
  end;

  try
    FileStream.LoadFromFile(EditInputFile.Text);
  except
    on EO: EFOpenError do begin
      MessageDlg('You have to choose an input file.', mtError, [mbOk], 0);
      Exit;
    end;
  end;
  try
    Stopwatch := TStopwatch.StartNew;
    EncodedStream := Encrypt.Encode(FileStream, @ProgressBar, @f, ChBoxText.Checked, ZeroByte);
    Elapsed := Stopwatch.Elapsed;
    StatusBar.SimpleText := 'Elapsed time: ' +
                              FloatToStr(Elapsed.TotalMilliseconds) + ' mills' +
                              ' or ' + FloatToStr(EncodedStream.Size /
                              Elapsed.TotalSeconds) + ' bytes per sec';
    if ZeroByte then FileName := EditOutputFile.Text + '.1'
                else FileName := EditOutputFile.Text;
    try
      EncodedStream.SaveToFile(FileName);
    except
      on EO: EFCreateError do begin
        MessageDlg('You have to choose an output file.', mtError, [mbOk], 0);
        Exit;
      end;
    end;
    EncodedStream.Free;
  finally
    FileStream.Free;
    if ChBoxText.Checked then CloseFile(f);
  end;
end;

procedure TMainForm.ActionGenerateKeysExecute(Sender: TObject);
begin
  try
    k := StrToInt64(Edit_K.Text);
    if not Encrypt.Initialize(k) then begin
      MessageDlg('Wrong value of the secret key K' + #13 +
                  'It must be a natural number > ' + IntToStr(MAX_P),
                  mtError, [mbOk], 0);
      Exit;
    end;
    ClearAll;
    ListBox_D.Items.AddStrings(Encrypt.GetSecretKeyList(MAX_LIST_N));
    MemoResult.Lines.Add('k = ' + IntToStr(k));
  except
    on EO: EConvertError do begin
      MessageDlg('Please input a secret key K.', mtError, [mbOk], 0);
      Exit;
    end;
  end;
end;

procedure TMainForm.ActionImportKeyExecute(Sender: TObject);
var d1: Int64;
    d: TInt64Array;
    f: file of Int64;
begin
  if OpenDialog.Execute then begin
    AssignFile(f, OpenDialog.FileName);
    Reset(f);
    Read(f, k);
    SetLength(d, 0);
    while not EOF(f) do begin
      Read(f, d1);
      SetLength(d, Length(d) + 1);
      d[High(d)] := d1;
    end;
    CloseFile(f);

    Encrypt.Initialize(k, @d);
    StatusBar.SimpleText := 'Key has been imported';
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Encrypt := TEncrypt.Create;
  SecretKeyList := TStringList.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Encrypt.Free;
  SecretKeyList.Free;
end;

procedure TMainForm.ListBox_DDblClick(Sender: TObject);
begin
  SecretKeyList.Add(ListBox_D.Items[ListBox_D.ItemIndex]);
  MemoResult.Lines.Add('d' + IntToStr(SecretKeyList.Count) +
                    ' = ' + ListBox_D.Items[ListBox_D.ItemIndex]);
end;

end.
