unit AFSPartitionUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,ComCtrls,StdCtrls,ExtCtrls,
 GJHCustomComponents;

type

 { TAFSPartitionForm }

 TAFSPartitionForm = class(TForm)
  OpenDFSFile: TOpenDialog;
  PartitionSizeLabel: TLabel;
  PartitionSize: TGJHSlider;
  rad_type40T,
  rad_type80T,
  rad_typeAFS,
  rad_typeDOS: TGJHRadioBox;
  FromFileButton,
  OKButton,
  CancelButton: TGJHButton;
  procedure FormCreate(Sender: TObject);
  procedure FormPaint(Sender: TObject);
  procedure PartitionSizeChange(Sender: TObject);
  procedure rad_typeClick(Sender: TObject);
  procedure FromFileClick(Sender: TObject);
 private

 public
  maxAFSSize,
  maxDOSSize : Cardinal;
  fromFile   : Boolean;
 end;

var
 AFSPartitionForm: TAFSPartitionForm;

implementation

uses MainUnit;

{$R *.lfm}

{ TAFSPartitionForm }

{------------------------------------------------------------------------------}
//Update the size label
{------------------------------------------------------------------------------}
procedure TAFSPartitionForm.PartitionSizeChange(Sender: TObject);
begin
 PartitionSizeLabel.Caption:=FloatToStr((PartitionSize.Position*$100)/1024)+'KB';
end;

{------------------------------------------------------------------------------}
//Ensure we don't create anything bigger than the FS can handle
{------------------------------------------------------------------------------}
procedure TAFSPartitionForm.rad_typeClick(Sender: TObject);
begin
 if rad_typeAFS.Ticked then PartitionSize.Max:=maxAFSSize;
 if rad_typeDOS.Ticked then PartitionSize.Max:=maxDOSSize;
end;

{------------------------------------------------------------------------------}
//Tile the form
{------------------------------------------------------------------------------}
procedure TAFSPartitionForm.FormPaint(Sender: TObject);
begin
 MainForm.FileInfoPanelPaint(Sender);
end;

{------------------------------------------------------------------------------}
//Create the form
{------------------------------------------------------------------------------}
procedure TAFSPartitionForm.FormCreate(Sender: TObject);
function CreateRadioBox(text: String): TGJHRadioBox;
begin
 Result:=TGJHRadioBox.Create(AFSPartitionForm as TControl);
 Result.Parent:=AFSPartitionForm as TWinControl;
 Result.Top:=PartitionSize.Top+PartitionSize.Height;
 Result.Visible:=True;
 Result.Caption:=text;
 Result.OnClick:=@rad_typeClick;
 Result.Font.Color:=clBlack;
end;
var
 ratio  : Real;
begin
 ratio:=PixelsPerInch/DesignTimePPI;
 //Create the slider
 PartitionSize:=TGJHSlider.Create(AFSPartitionForm as TControl);
 PartitionSize.Parent:=AFSPartitionForm as TWinControl;
 PartitionSize.Top:=PartitionSizeLabel.Height;
 PartitionSize.Align:=alTop;
 PartitionSize.Orientation:=csHorizontal;
 PartitionSize.Height:=Round(30*ratio);
 PartitionSize.Min:=0;
 PartitionSize.Max:=10;
 PartitionSize.Pointers:=False;
 PartitionSize.Outline:=csOutInner;
 PartitionSize.OnChange:=@PartitionSizeChange;
 PartitionSize.Font.Color:=clBlack;
 //Create the radio boxes
 rad_typeAFS:=CreateRadioBox('Acorn File Server');
 rad_typeDOS:=CreateRadioBox('DOS Plus');
 rad_type40T:=CreateRadioBox('40 Track');
 rad_type80T:=CreateRadioBox('80 Track');
 //Create the buttons
 FromFileButton:=MainForm.CreateButton(AFSPartitionForm as TControl,
                                       'From File...',False,Round(8*ratio),
                              rad_typeAFS.Top+rad_typeAFS.Height+Round(8*ratio),
                                       mrNone);
 FromFileButton.Enabled:=False;
 FromFileButton.OnClick:=@FromFileClick;
 CancelButton:=MainForm.CreateButton(AFSPartitionForm as TControl,'Cancel',
                                     False,
                        FromFileButton.Left+FromFileButton.Width+Round(8*ratio),
                                     FromFileButton.Top,mrCancel);
 OKButton:=MainForm.CreateButton(AFSPartitionForm as TControl,'OK',True,
                            CancelButton.Left+CancelButton.Width+Round(8*ratio),
                                 FromFileButton.Top-Round(4*ratio),mrOK);
 Width:=OKButton.Left+OKButton.Width+8;
 //Adjust the radio button positions
 rad_typeAFS.Left:=Round(8*ratio);
 rad_typeDOS.Left:=Width div 2;
 rad_type40T.Left:=rad_typeAFS.Left;
 rad_type80T.Left:=rad_typeDOS.Left;
 //Adjust the form height
 Height:=OKButton.Top+OKButton.Height+Round(8*ratio);
end;

{------------------------------------------------------------------------------}
//User clicked on 'From File'
{------------------------------------------------------------------------------}
procedure TAFSPartitionForm.FromFileClick(Sender: TObject);
begin
 FromFileButton.ModalResult:=mrNone;
 //Currently only for adding DFS image
 if OpenDFSFile.Execute then
 begin
  fromFile:=True;
  FromFileButton.ModalResult:=mrOK;
 end;
end;

end.

