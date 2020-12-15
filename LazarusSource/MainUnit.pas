unit MainUnit;

//This project is now covered by the GNU GPL v3 licence

{$MODE objFPC}

interface

uses
  SysUtils,Classes,Graphics,Controls,Forms,Dialogs,StdCtrls,DiscImage,ExtCtrls,
  Buttons,ComCtrls,Menus,DateUtils,ImgList,StrUtils;

type
 //We need a custom TTreeNode, as we want to tag on some extra information
 TMyTreeNode = class(TTreeNode)
  private
   FDir     : Integer;
   FIsDir   : Boolean;
  public
   property Dir     : Integer read FDir write FDir;     //Directory reference
   property IsDir   : Boolean read FIsDir write FIsDir; //Is it a directory
 end;
 //Form definition

  { TMainForm }

  TMainForm = class(TForm)
   cb_private: TCheckBox;
   cb_ownerwrite: TCheckBox;
   cb_ownerread: TCheckBox;
   cb_ownerlocked: TCheckBox;
   cb_ownerexecute: TCheckBox;
   cb_publicread: TCheckBox;
   cb_publicwrite: TCheckBox;
   cb_publicexecute: TCheckBox;
    ed_filenamesearch: TEdit;
    ed_filetypesearch: TEdit;
    ed_lengthsearch: TEdit;
    Label15: TLabel;
    Label7: TLabel;
    ToolBarImages: TImageList;
    Label10: TLabel;
    Label14: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    AddNewFile: TOpenDialog;
    Panel1: TPanel;
    SaveImage: TSaveDialog;
    sb_search: TSpeedButton;
    searchresultscount: TLabel;
    ToolBar1: TToolBar;
    btn_OpenImage: TToolButton;
    btn_SaveImage: TToolButton;
    btn_Delete: TToolButton;
    btn_Rename: TToolButton;
    btn_AddFiles: TToolButton;
    ToolButton3: TToolButton;
    btn_download: TToolButton;
    ToolButton5: TToolButton;
    btn_About: TToolButton;
    ToolPanel: TPanel;
    OpenImageFile: TOpenDialog;
    ExtractDialogue: TSaveDialog;
    DirList: TTreeView;
    FileImages: TImageList;
    FullSizeTypes: TImageList;
    FileInfoPanel: TPanel;
    img_FileType: TImage;
    lb_FileName: TLabel;
    Label1: TLabel;
    lb_FileType: TLabel;
    Label3: TLabel;
    Label2: TLabel;
    lb_execaddr: TLabel;
    lb_loadaddr: TLabel;
    Label6: TLabel;
    lb_timestamp: TLabel;
    Label5: TLabel;
    Label11: TLabel;
    lb_length: TLabel;
    lb_Parent: TLabel;
    Label12: TLabel;
    lb_title: TLabel;
    Label13: TLabel;
    Label4: TLabel;
    lb_location: TLabel;
    Label21: TLabel;
    ImageContentsPanel: TPanel;
    lb_contents: TLabel;
    SearchPanel: TPanel;
    lb_searchresults: TListBox;
    FIle_Menu: TPopupMenu;
    ExtractFile1: TMenuItem;
    RenameFile1: TMenuItem;
    DeleteFile1: TMenuItem;
    StatusBar: TStatusBar;
    AddFile1: TMenuItem;
    NewDirectory1: TMenuItem;
    procedure btn_SaveImageClick(Sender: TObject);
    procedure AttributeChangeClick(Sender: TObject);
    function GetFilePath(Node: TTreeNode): AnsiString;
    procedure DeleteFile1Click(Sender: TObject);
    procedure DirListCreateNodeClass(Sender: TCustomTreeView; var NodeClass: TTreeNodeClass);
    procedure DirListEditingEnd(Sender: TObject; Node: TTreeNode;
     Cancel: Boolean);
    procedure DirListGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RenameFile1Click(Sender: TObject);
    procedure ResetFileFields;
    procedure ResetSearchFields;
    procedure btn_downloadClick(Sender: TObject);
    function GetImageFilename(dir,entry: Integer): AnsiString;
    function GetWindowsFilename(dir,entry: Integer): AnsiString;
    procedure DownLoadFile(dir,entry: Integer; path: AnsiString);
    procedure DownLoadDirectory(dir,entry: Integer; path: AnsiString);
    procedure btn_OpenImageClick(Sender: TObject);
    function ConvertToKMG(size: Int64): AnsiString;
    function IntToStrComma(size: Int64): AnsiString;
    procedure DirListChange(Sender: TObject; Node: TTreeNode);
    procedure btn_AboutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BBCtoWin(var f: AnsiString);
    procedure ValidateFilename(var f: AnsiString);
    procedure sb_searchClick(Sender: TObject);
    procedure lb_searchresultsClick(Sender: TObject);
    procedure DirListEditing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure DirListDblClick(Sender: TObject);
    procedure AddFile1Click(Sender: TObject);
    procedure UpdateImageInfo;
  private
   var
    //To keep track of renames
    PathBeforeEdit,
    NameBeforeEdit:AnsiString;
    //Stop the checkbox OnClick from firing when just changing the values
    DoNotUpdate   :Boolean;
   const
    //RISC OS Filetypes - used to locate the appropriate icon in the ImageList
    FileTypes: array[3..50] of AnsiString =
                              ('690','695','AE9','AF1','AFF','B60','BC5','BD9',
                               'BDA','BE8','C25','C27','C85','D87','D88','D89',
                               'D94','F9D','F9E','F9F','FAE','FB1','FB4','FC6',
                               'FC8','FCA','FCC','FD4','FD6','FD7','FE4','FEA',
                               'FEB','FEC','FED','FF2','FF4','FF5','FF6','FF7',
                               'FF8','FF9','FFA','FFB','FFC','FFD','FFE','FFF');
    //Windows extension - used to translate from RISC OS to Windows
    Extensions: array[1..12] of AnsiString =
                              ('69Cbmp','ADFpdf' ,'B60png','C46tar',   'C85jpg',
                               'DDCzip','FF0tiff','FF6ttf','FF9sprite','FFBbas',
                               'FFDdat','FFFtxt');
    //These point to certain icons used when no filetype is found, or non-ADFS
    application =  0;
    directory   =  1;
    directory_o =  2;
    loadexec    = 51; //RISC OS file with Load/Exec specified
    unknown     = 52; //RISC OS unknown filetype
    nonadfs     = 54; //All other filing systems, except for D64/D71/D81
    prgfile     = 53; //D64/D71/D81 file types
    seqfile     = 54;
    usrfile     = 55;
    delfile     = 56;
    relfile     = 54;
    cbmfile     = 54;
    //Application Title
    ApplicationTitle   = 'Disc Image Manager';
    ApplicationVersion = '1.05.4';
  public
   //The image - this doesn't need to be public...we are the main form in this
   Image: TDiscImage;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses AboutUnit;

//Add a new file to the disc image (DFS only at the moment)
procedure TMainForm.AddFile1Click(Sender: TObject);
var
  NewFile        : TDirEntry;
  buffer         : TDIByteArray;
  i,index        : Integer;
  side,ptr       : Cardinal;
  importfilename,
  inffile,
  execaddr,
  loadaddr       : AnsiString;
  fields         : array of AnsiString;
  chr            : Char;
  F              : TFileStream;
begin
 //Find out which side of a DFS disc it is
 if Image.FormatNumber mod 2=1 then //Only for double sided
 //As with DFS we can only Add with the root selected, the index will be the side
  side:=DirList.Selected.Index
 else
 //Not double sided, so assume side 0
  side:=0;
 //Open the dialogue box
 if AddNewFile.Execute then
  if AddNewFile.Files.Count>0 then
   //If more than one file selected, iterate through them
   for i:=0 to AddNewFile.Files.Count-1 do
   begin
    //Extract the filename
    importfilename:=ExtractFileName(AddNewFile.Files[i]);
    //Remove any extraenous specifiers
    while (importfilename[4]='.') do
     importfilename:=RightStr(importfilename,Length(importfilename)-2);
    //If root, remove the directory specifier
    if (importfilename[2]='.') and (importfilename[1]='$') then
     importfilename:=RightStr(importfilename,Length(importfilename)-2);
    //Make sure the file does not exist already
    if not(Image.FileExists(':'+IntToStr(side)+'.$.'+importfilename,ptr)) then
    begin
     //Initialise the TDirArray
     ResetDirEntry(NewFile);
     //Initialise the buffer
     SetLength(buffer,0);
     //Initialise the addresses
     execaddr:='00000000';
     loadaddr:='00000000';
     //Is there an inf file?
     if FileExists(AddNewFile.Files[i]+'.inf') then
     begin
      inffile:='';
      //Read in the first line
      F:=TFileStream.Create(AddNewFile.Files[i]+'.inf',fmOpenRead);
      F.Position:=0;
      while (F.Read(chr,1)=1) and (Ord(chr)>31) and (Ord(chr)<127) do
       inffile:=inffile+chr;
      F.Free;
      //Decode the line - first we get rid of double spaces
      while Pos('  ',inffile)<>0 do
       inffile:=ReplaceStr(inffile,'  ',' ');
      //Now split the string at the spaces
      fields:=inffile.Split(' ');
      //Then extract the fields
      if Length(fields)>1 then loadaddr:=fields[1];
      if length(fields)>2 then execaddr:=fields[2];
     end;
     //Setup the record
     NewFile.Filename:=importfilename;
     NewFile.ExecAddr:=StrToInt('$'+execaddr);
     NewFile.LoadAddr:=StrToInt('$'+loadaddr);
     NewFile.Side    :=side;
     //Load the file from the host
     F:=TFileStream.Create(AddNewFile.Files[i],fmOpenRead);
     F.Position:=0;
     SetLength(buffer,F.Size);
     NewFile.Length:=F.Read(buffer[0],F.Size);
     F.Free;
     //Write the File
     index:=Image.WriteFile(NewFile,buffer);
     if index<>-1 then //File added OK
     begin
      //Now add the entry to the Directory List
      if DirList.Selected.HasChildren then
       //Insert it before the one specified
       DirList.Items.Insert(DirList.Selected.Items[index],importfilename)
      else
       //Is the first child, so just add it
       DirList.Items.AddChildFirst(DirList.Selected,importfilename);
      //And update the free space display
      UpdateImageInfo;
     end;
    end;
   end;
 {
 DirList.Items.Insert(<node>,<string>) - inserts a new node before <node>
 DirList.Items.AddChildFirst(<node>,<string>) - inserts a new node as the first child of <node>
 DirList.Items.Add(<node>,<string>) - inserts a new node as the last child of <node>
 DirList.Selected.GetFirstChild - gets the first child node
 See:
 http://docs.embarcadero.com/products/rad_studio/radstudio2007/RS2007_helpupdates/HUpdate3/EN/html/delphivclwin32/!!MEMBERTYPE_Methods_ComCtrls_TTreeNodes.html
 }
end;

//About box
procedure TMainForm.btn_AboutClick(Sender: TObject);
var
 platform: AnsiString;
begin
 //Update the Application Title
 AboutForm.lb_Title.Caption:=ApplicationTitle;
 //Determine the current platform (compile time directive)
 platform:='';
 {$IFDEF Darwin}
 platform:=' macOS';            //Apple Mac OS X (64 bit only)
 {$ENDIF}
 {$IFDEF Win32}
 platform:=' Windows 32 bit';   //Microsoft Windows 32 bit
 {$ENDIF}
 {$IFDEF Win64}
 platform:=' Windows 64 bit';   //Microsoft Windows 64 bit
 {$ENDIF}
 {$IFDEF Linux}
 platform:=' Linux';            //Linux, all flavours (64 bit only)
 {$ENDIF}
 //Update the Application Version
 AboutForm.lb_Version.Caption:='Version '+ApplicationVersion+platform;
 //Show the Form, as a modal
 AboutForm.ShowModal;
end;

//User has clicked download file button
procedure TMainForm.btn_downloadClick(Sender: TObject);
var
 Node       : TTreeNode;
 entry,
 dir,s      : Integer;
 saver      : Boolean;
begin
 if DirList.SelectionCount>0 then
  for s:=0 to DirList.SelectionCount-1 do
   begin
    //Get one of the selected Nodes
    Node:=DirList.Selections[s];
    //Only act on it if there is one selected
    if Node<>nil then
     begin
      //Get the entry and directory references into 'Image'
      entry:=Node.Index;
      dir:=-1;//This will remain as -1 with the root
      if Node.Parent<>nil then
       dir  :=TMyTreeNode(Node).Dir;
      if dir>=0 then //dir = -1 would be the root
      begin
       //Open the Save As dialogue box, but only if the first in the list
       saver:=False;
       if s=0 then
       begin
        ExtractDialogue.FileName:=GetWindowsFilename(dir,entry);
        saver:=ExtractDialogue.Execute;
       end;
       if s>0 then saver:=True;
       //Download a single file
       if saver then
        DownLoadFile(dir,entry,ExtractFilePath(ExtractDialogue.FileName));
      end
      else
       if DirList.SelectionCount=1 then
        ShowMessage('Cannot act on root directory');
     end;
   end;
end;

//Create an Image filename
function TMainForm.GetImageFilename(dir,entry: Integer): AnsiString;
begin
 Result:=Image.Disc[dir].Entries[entry].Parent+Image.DirSep
        +Image.Disc[dir].Entries[entry].Filename;
end;

//Create a Windows filename
function TMainForm.GetWindowsFilename(dir,entry: Integer): AnsiString;
begin
 //Get the filename
 Result:=Image.Disc[dir].Entries[entry].Filename;
 //Add the filetype to the end, if any (but not directories)
 if (Image.Disc[dir].Entries[entry].ShortFileType<>'')
 and(Image.Disc[dir].Entries[entry].DirRef=-1) then
  Result:=Result+','+Image.Disc[dir].Entries[entry].ShortFileType;
 //Convert BBC chars to PC
 BBCtoWin(Result);
 //Replace any non-valid characters
 ValidateFilename(Result);
end;

//Download a file
procedure TMainForm.DownLoadFile(dir,entry: Integer;path: AnsiString);
var
 buffer         : TDIByteArray;
 F              : TFileStream;
 inffile,
 imagefilename,
 windowsfilename: AnsiString;
begin
 // Ensure path ends in a directory separator
 if path[Length(path)]<>PathDelim then path:=path+PathDelim;
 //Object is a file, so download it
 if Image.Disc[dir].Entries[entry].DirRef=-1 then
 begin
  //Get the full path and filename
  imagefilename  :=GetImageFilename(dir,entry);
  windowsfilename:=GetWindowsFilename(dir,entry);
  if Image.ExtractFile(imagefilename,buffer) then
  begin
   //Save the buffer to the file
   F:=TFileStream.Create(path+windowsfilename,fmCreate);
   F.Position:=0;
   F.Write(buffer[0],Length(buffer));
   F.Free;
   //Create the inf file
   if Image.FormatNumber shr 4<2 then //DFS and ADFS only
   begin
    inffile:=PadRight(LeftStr(windowsfilename,12),12)+' '
            +IntToHex(Image.Disc[dir].Entries[entry].LoadAddr,8)+' '
            +IntToHex(Image.Disc[dir].Entries[entry].ExecAddr,8);
    F:=TFileStream.Create(path+windowsfilename+'.inf',fmCreate);
    F.Position:=0;
    F.Write(inffile[1],Length(inffile));
    F.Free;
   end;
  end
  //Happens if the file could not be located
  else ShowMessage('Could not locate file "'+imagefilename+'"');
 end
 else DownLoadDirectory(dir,entry,path+windowsfilename);
end;

//Download an entire directory
procedure TMainForm.DownLoadDirectory(dir,entry: Integer;path: AnsiString);
var
 imagefilename,
 windowsfilename: AnsiString;
 ref            : Cardinal;
 c,s            : Integer;
begin
 ref:=0;
 // Ensure path ends in a directory separator
 if path[Length(path)]<>PathDelim then path:=path+PathDelim;
 //Get the full path and filename
 imagefilename:=GetImageFilename(dir,entry);
 //Convert to Windows filename
 windowsfilename:=GetWindowsFilename(dir,entry);
 if Image.FileExists(imagefilename,ref) then
 begin
  //Create the directory
  if not DirectoryExists(path+windowsfilename) then
   CreateDir(path+windowsfilename);
  //Navigate into the directory
  s:=Image.Disc[dir].Entries[entry].DirRef;
  //Iterate through the entries
  for c:=0 to Length(Image.Disc[s].Entries)-1 do
   DownLoadFile(s,c,path+windowsfilename);
 end
 //Happens if the file could not be located
 else ShowMessage('Could not locate directory "'+imagefilename+'"');
end;

//User has clicked on the button to open a new image
procedure TMainForm.btn_OpenImageClick(Sender: TObject);
var
 //Used as a marker to make sure all directories are displayed.
 //Some double sided discs have each side as separate discs
 highdir    : Integer;
 //Adds a directory to the TreeView - is called recursively to drill down the tree
 procedure AddDirectory(CurrDir: TTreeNode; dir: Integer);
 var
  entry: Integer;
  Node: TTreeNode;
 begin
  //Make a note of the dir ref, it is the highest
  if dir>highdir then highdir:=dir;
  //Set the 'IsDir' flag to true, as this is a directory
  TMyTreeNode(CurrDir).IsDir:=True;
  //Iterate though all the entries
  for entry:=0 to Length(Image.Disc[dir].Entries)-1 do
  begin
   //Adding new nodes for each one
   Node:=DirList.Items.AddChild(CurrDir,Image.Disc[dir].Entries[entry].Filename);
   //Making a note of the dir ref
   TMyTreeNode(Node).Dir:=dir;
   //And setting the IsDir flag to false - this will be set to True if it is a dir
   TMyTreeNode(Node).IsDir:=False;
   //If it is, indeed, a direcotry, the dir ref will point to the sub-dir
   if Image.Disc[dir].Entries[entry].DirRef>=0 then
   //and we'll recursively call ourself to add these entries
    AddDirectory(Node,Image.Disc[dir].Entries[entry].DirRef);
  end;
 end;
begin
 //Show the open file dialogue box
 if OpenImageFile.Execute then
 begin
  //Clear all the labels, and enable/disable the buttons
  ResetFileFields;
  //Clear the search fields
  ResetSearchFields;
  //Load the image and create the catalogue
  Image.LoadFromFile(OpenImageFile.FileName);
  //Change the application title (what appears on SHIFT+TAB, etc.)
  Caption:=ApplicationTitle+' - '+ExtractFileName(OpenImageFile.FileName);
  //If the format is a recognised one
  if Image.FormatString<>'' then
  begin
   //Populate the tree view
   DirList.Items.Clear;
   //Set the highdir to zero - which will be root to start with
   highdir:=0;
   //Then add the directories, if there is at least one
   if Length(Image.Disc)>0 then
   begin
    //Start by adding the root (could be more than one root, particularly on
    //double sided discs)
    repeat
     //This will initiate the recursion through the directory structure, per side
     AddDirectory(DirList.Items.Add(nil,Image.Disc[highdir].Directory),highdir);
     //Finished on this directory structure, so increase the highdir
     inc(highdir);
     //and continue until we have everything on the disc. This will, in effect,
     //add the second root for double sided discs.
    until highdir=Length(Image.Disc);
    //Expand the top level of the tree
    DirList.TopItem.Expand(False);
    //And the root for the other side of the disc
    if Image.DoubleSided then
    begin
     //First, we need to find it
     repeat
      inc(highdir)
      //If there is one, of course - but it must be a directory
     until (highdir>=DirList.Items.Count) or (TMyTreeNode(DirList.Items[highdir-1]).IsDir);
     if highdir>DirList.Items.Count then
      highdir:=DirList.Items.Count;
     //Found? then expand it
     if TMyTreeNode(DirList.Items[highdir-1]).IsDir then
      DirList.Items[highdir-1].Expand(False);
    end;
   end;
   //Populate the info box
   UpdateImageInfo;
   //Enable the controls
   btn_SaveImage.Enabled:=True;
   //Enable the search area
   ed_filenamesearch.Enabled:=True;
   ed_lengthsearch.Enabled  :=True;
   ed_filetypesearch.Enabled:=True;
   lb_searchresults.Enabled :=True;
   sb_search.Enabled        :=True;
   //Enable the directory view
   DirList.Enabled:=True;
  end;
 end;
end;

//Update the Image information display
procedure TMainForm.UpdateImageInfo;
begin
 StatusBar.Panels[0].Text:=Image.FormatString;
 StatusBar.Panels[1].Text:=Image.Title;
 StatusBar.Panels[2].Text:=ConvertToKMG(Image.DiscSize)
                          +' ('+IntToStrComma(Image.DiscSize)+' Bytes)';
 StatusBar.Panels[3].Text:=ConvertToKMG(Image.FreeSpace)
                          +' ('+IntToStrComma(Image.FreeSpace)+' Bytes)';
 if Image.DoubleSided then
  StatusBar.Panels[4].Text:='Double Sided'
 else
  StatusBar.Panels[4].Text:='Single Sided';
 StatusBar.Panels[5].Text:=Image.MapTypeString;
 StatusBar.Panels[6].Text:=Image.DirectoryTypeString;
end;

//This is called when the selection changes on the TreeView
procedure TMainForm.DirListChange(Sender: TObject; Node: TTreeNode);
var
 entry,
 dir,
 ft       : Integer;
 filename,
 filetype,
 location,
 multiple : AnsiString;
begin
 //Disable the AddFile menu item
 AddFile1.Enabled    :=False;
 btn_AddFiles.Enabled:=False;
 //More than one?
 multiple:='';
 if DirList.SelectionCount>1 then multiple:='s';
 //Change the menu names - we'll change these to 'Directory', if needed, later
 ExtractFile1.Caption:='&Extract File'+multiple;
 btn_download.Hint:='Extract File'+multiple;
 RenameFile1.Caption :='&Rename File'+multiple;
 btn_Rename.Hint:='Rename File'+multiple;
 DeleteFile1.Caption :='&Delete File'+multiple;
 btn_Delete.Hint:='Delete File'+multiple;
 //Enable the buttons, if there is a selection
 if DirList.SelectionCount>0 then
 begin
  btn_download.Enabled:=True;
  ExtractFile1.Enabled:=True;
  DeleteFile1.Enabled :=True;
  btn_Delete.Enabled  :=True;
 end
 else
 begin
  //Disable buttons if not
  btn_download.Enabled:=False;
  ExtractFile1.Enabled:=False;
  DeleteFile1.Enabled :=False;
  btn_Delete.Enabled  :=False;
 end;
 //Enable the Add Files and Rename menu
 if DirList.SelectionCount=1 then
 begin
  AddFile1.Enabled    :=True;
  btn_AddFiles.Enabled:=True;
  RenameFile1.Enabled :=True;
  btn_Rename.Enabled  :=True;
 end
 else //Disable otherwise
 begin
  AddFile1.Enabled    :=False;
  btn_AddFiles.Enabled:=False;
  RenameFile1.Enabled :=False;
  btn_Rename.Enabled  :=False;
 end;
 //Reset the file details panel
 ResetFileFields;
 DoNotUpdate   :=True;
 if Node<>nil then //Just being careful!!!
 begin
  //Get the entry and dir references
  entry:=Node.Index;
  dir:=-1;
  //Clear the filename variable
  filename:='';
  //If the node does not have a parent, then the dir ref is the one contained
  //in the extra info. Otherwise is -1
  if Node.Parent<>nil then
   dir  :=TMyTreeNode(Node).Dir;
  //Then, get the filename and filetype of the file...not directory
  if dir>=0 then
  begin
   filename:=Image.Disc[dir].Entries[entry].Filename;
   //Attributes
   cb_ownerwrite.Checked   :=Pos('W',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_ownerread.Checked    :=Pos('R',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_ownerlocked.Checked  :=Pos('L',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_ownerexecute.Checked :=Pos('E',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_publicwrite.Checked  :=Pos('w',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_publicread.Checked   :=Pos('r',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_publicexecute.Checked:=Pos('e',Image.Disc[dir].Entries[entry].Attributes)>0;
   cb_private.Checked      :=Pos('P',Image.Disc[dir].Entries[entry].Attributes)>0;
   //Enable whichever tickboxes are appropriate to the system
   if Image.FormatNumber div $10=0 then //DFS
    cb_ownerlocked.Enabled   :=True;
   if Image.FormatNumber div $10=1 then //ADFS
   begin
    cb_ownerwrite.Enabled    :=True;
    cb_ownerread.Enabled     :=True;
    cb_ownerlocked.Enabled   :=True;
    cb_publicwrite.Enabled   :=True;
    cb_publicread.Enabled    :=True;
    if Image.FormatNumber mod $10<3 then //ADFS Old Directory
    begin
     cb_ownerexecute.Enabled  :=True;
     cb_publicexecute.Enabled :=True;
     cb_private.Enabled       :=True;
    end;
   end;
   //Filetype
   filetype:=Image.Disc[dir].Entries[entry].Filetype;
  end
  else //Disable buttons as we are on the root
  begin
   btn_download.Enabled:=False;
   ExtractFile1.Enabled:=False;
   DeleteFile1.Enabled :=False;
   btn_Delete.Enabled  :=False;
   RenameFile1.Enabled :=False;
   btn_Rename.Enabled  :=False;
  end;
  //If it is a directory, however, we need to get the filename from somewhere else
  //and the filetype will be either Directory or Application (RISC OS only)
  if TMyTreeNode(Node).IsDir then
  begin
   //Determine if it is a Directory or an ADFS Application
   if filename='' then
     filename:=Image.Disc[entry].Directory;
   if  (Copy(filename,1,1)='!') //Application indicated by '!' as first char
   and (Image.FormatNumber>$12) and (Image.FormatNumber<$1F) then //RISC OS
    filetype:='Application'
   else
    filetype:='Directory';
   //Change the menu text
   ExtractFile1.Caption:='&Extract '+filetype;
   btn_download.Hint   :='Extract '+filetype;
   RenameFile1.Caption :='&Rename '+filetype;
   btn_Rename.Hint     :='Rename '+filetype;
   DeleteFile1.Caption :='&Delete '+filetype;
   btn_Delete.Hint     :='Delete '+filetype;
   //Report if directory is broken and include the error code
   if Image.Disc[entry].Broken then
    filetype:=filetype+' (BROKEN - 0x'
                      +IntToHex(Image.Disc[entry].ErrorCode,2)+')';
   if dir>=0 then
    lb_title.Caption:=Image.Disc[dir].Title;
  end
  else //Can only add files to a directory
  begin
   AddFile1.Enabled    :=False;
   btn_AddFiles.Enabled:=False;
  end;
  //Filename
  lb_FileName.Caption:=filename;
  //Filetype Image
  ft:=Node.ImageIndex;
  if (ft=directory) or (ft=directory_o) then
  begin
   if Copy(filename,1,1)='!' then //or application
    ft:=application
   else
    ft:=directory;
  end;
  //Create a purple background, as a transparent mask
  img_FileType.Transparent:=True;
  img_FileType.Canvas.Pen.Color:=$FF00FF;
  img_FileType.Canvas.Brush.Color:=$FF00FF;
  img_FileType.Canvas.Rectangle(0,0,34,34);
  //Paint the picture onto it
  FullSizeTypes.GetBitmap(ft,img_FileType.Picture.Bitmap);
  //Filetype text
  lb_FileType.Caption:=filetype;
  if dir>=0 then
  begin
   //Parent
   lb_parent.Caption:=Image.Disc[dir].Entries[entry].Parent;
   //Timestamp
   if Image.Disc[dir].Entries[entry].TimeStamp>0 then
    lb_timestamp.Caption:=FormatDateTime('hh:nn:ss dd mmm yyyy',
                                       Image.Disc[dir].Entries[entry].TimeStamp)
   else
   begin
    //Load address
    lb_loadaddr.Caption:='0x'+IntToHex(Image.Disc[dir].Entries[entry].LoadAddr,8);
    //Execution address
    lb_execaddr.Caption:='0x'+IntToHex(Image.Disc[dir].Entries[entry].ExecAddr,8);
   end;
   //Length
   lb_length.Caption:=ConvertToKMG(Image.Disc[dir].Entries[entry].Length)+
                   ' (0x'+IntToHex(Image.Disc[dir].Entries[entry].Length,8)+')';
   //Location of object - varies between formats
   location:='';
   //ADFS Old map - Sector is an offset
   if Image.MapType=$00 then
    location:='Offset: 0x'+IntToHex(Image.Disc[dir].Entries[entry].Sector,8);
   //ADFS New map - Sector is an indirect address (fragment and sector)
   if Image.MapType=$01 then
    location:='Indirect address: 0x'+IntToHex(Image.Disc[dir].Entries[entry].Sector,8);
   //Commodore formats - Sector and Track
   if ((Image.FormatNumber>=$20) and (Image.FormatNumber<=$2F)) then
    location:='Track ' +IntToStr(Image.Disc[dir].Entries[entry].Track);
   //All other formats - Sector
   if (Image.FormatNumber<=$0F)
   or ((Image.FormatNumber>=$20) and (Image.FormatNumber<=$2F))
   or ((Image.FormatNumber>=$40) and (Image.FormatNumber<=$4F)) then
    location:=location+' Sector '+IntToStr(Image.Disc[dir].Entries[entry].Sector);
   //DFS - indicates which side also
   if Image.FormatNumber<=$0F then
    location:=location+' Side '  +IntToStr(Image.Disc[dir].Entries[entry].Side);
   lb_location.Caption:=location;
  end;
  //Update the image
  DirListGetImageIndex(Sender, Node);
 end;
 DoNotUpdate   :=False;
end;

//Called when the TreeView is updated, and it wants to know which icon to use
procedure TMainForm.DirListGetImageIndex(Sender: TObject; Node: TTreeNode);
var
 ft,i,dir,entry: Integer;
 filetype      : AnsiString;
begin
 //The directory and entry references, as always
 dir  :=TMyTreeNode(Node).Dir;
 entry:=Node.Index;
 //Are we ADFS?
 if (Image.FormatNumber>=$10) and (Image.FormatNumber<=$1F) then
 begin
  //Default is a file with load and exec address
  ft:=loadexec;
  //If it is not a directory
  if not TMyTreeNode(Node).IsDir then
  begin
   //And has a timestamp
   if Image.Disc[dir].Entries[entry].TimeStamp>0 then
   begin
    //Then we become an unknown filetype, until found that is
    ft:=unknown;
    //Start of search - the filetype constant array
    i:=Low(FileTypes)-1;
    //The filetype of the file
    filetype:=Image.Disc[dir].Entries[entry].ShortFiletype;
    //Just iterate through until we find a match, or get to the end
    repeat
     inc(i)
    until (filetype=FileTypes[i])
      or (i=High(FileTypes));
    //Do we have a match? Make a note
    if filetype=FileTypes[i] then ft:=i;
   end;
  end;
 end
 else
  //Is it a Commodore format?
  if (Image.FormatNumber>=$20) and (Image.FormatNumber<=$2F) then
  begin
   //Default is a PRG file
   ft:=prgfile;
   //Directory has a different icon
   if not TMyTreeNode(Node).IsDir then
   begin
    //Get the appropriate filetype - no array for this as there is only 5 of them
    if Image.Disc[dir].Entries[entry].ShortFileType='SEQ' then ft:=seqfile;
    if Image.Disc[dir].Entries[entry].ShortFileType='USR' then ft:=usrfile;
    if Image.Disc[dir].Entries[entry].ShortFileType='REL' then ft:=relfile;
    if Image.Disc[dir].Entries[entry].ShortFileType='DEL' then ft:=delfile;
    if Image.Disc[dir].Entries[entry].ShortFileType='CBM' then ft:=cbmfile;
   end;
  end
  else
   //If not ADFS or Commodore, use a default icon
   ft:=nonadfs; //(which is actually from ADFS in RISC OS 3.11!!)
 //Diectory icons
 if TMyTreeNode(Node).IsDir then
 begin
  //Different icon if it is expanded, i.e. open
  if Node.Expanded then
   ft:=directory_o
  else
   //to a closed one
   ft:=directory;
  //Following doesn't work, hence why it is commented out
//  if Copy(Image.Disc[dir].Entries[entry].Filename,1,1)='!' then
//   ft:=application;
 end;
 //Tell the system what the ImageList reference is
 Node.ImageIndex:=ft;
 //And ensure it stays selected
 Node.SelectedIndex:=Node.ImageIndex;
end;

//Form is getting resized
procedure TMainForm.FormResize(Sender: TObject);
begin
 if Height<634 then Height:=634; //Minimum height
 if Width<664 then Width:=664; //Minimum width
end;

//Initialise Form
procedure TMainForm.FormShow(Sender: TObject);
begin
 //Initial width and height of form
 Width:=921;
 Height:=751;
 //Enable or disable buttons
 btn_OpenImage.Enabled    :=True;
 btn_SaveImage.Enabled    :=False;
 btn_About.Enabled        :=True;
 btn_download.Enabled     :=False;
 btn_Delete.Enabled       :=False;
 btn_Rename.Enabled       :=False;
 btn_AddFiles.Enabled     :=False;
 //Menu items
 ExtractFile1.Enabled     :=False;
 RenameFile1.Enabled      :=False;
 DeleteFile1.Enabled      :=False;
 AddFile1.Enabled         :=False;
 NewDirectory1.Enabled    :=False;
 //Disable the search area
 ed_filenamesearch.Enabled:=False;
 ed_lengthsearch.Enabled  :=False;
 ed_filetypesearch.Enabled:=False;
 lb_searchresults.Enabled :=False;
 sb_search.Enabled        :=False;
 //Disable the directory view
 DirList.Enabled          :=False;
 //Reset the file details panel
 ResetFileFields;
 //Clear the search fields
 ResetSearchFields;
 //Clear the status bar
 UpdateImageInfo;
 //Reset the tracking variables
 PathBeforeEdit:='';
 NameBeforeEdit:='';
end;

//This is called when the form is created - i.e. when the application is created
procedure TMainForm.FormCreate(Sender: TObject);
begin
 //Just updates the title bar
 Caption:=ApplicationTitle;
 //Create the image instance
 Image:=TDiscImage.Create;
end;

//Highlight the file in the tree
procedure TMainForm.lb_searchresultsClick(Sender: TObject);
var
 i,s,
 dir,
 entry : Integer;
 ptr   : Cardinal;
begin
 ptr:=0;
 //Selected item: -1 for none
 s:=-1;
 //Find the selected item
 for i:=0 to lb_searchresults.Items.Count-1 do
  if lb_searchresults.Selected[i] then s:=i;
 //Found? So highlight it
 if s>=0 then
 begin
  //First, get the reference
  Image.FileExists(lb_searchresults.Items[s],ptr);
  entry:=ptr mod $10000;  //Bottom 16 bits - entry reference
  dir  :=ptr div $10000;  //Top 16 bits - directory reference
  //Then find the node
  for i:=0 to DirList.Items.Count-1 do
   if  (TMyTreeNode(DirList.Items[i]).Dir=dir)
   and (DirList.Items[i].Index=entry) then
    //and select it
    DirList.Items[i].Selected:=True;
  //Deselect the item in the search window
  lb_searchresults.Selected[s]:=False;
  //We'll need to give the tree focus, so it shows up
  DirList.SetFocus;
 end;
end;

//This just creates our custom TTreeNode
procedure TMainForm.DirListCreateNodeClass(Sender: TCustomTreeView;
  var NodeClass: TTreeNodeClass);
begin
  NodeClass:=TMyTreeNode;
end;

//Save the Image to disc
procedure TMainForm.btn_SaveImageClick(Sender: TObject);
var
 ext,
 filename: AnsiString;
begin
 //Remove the existing part of the original filename
 filename:=ExtractFileName(Image.Filename);
 ext:=ExtractFileExt(filename);
 filename:=LeftStr(filename,Length(filename)-Length(ext));
 //Populate the filename part of the dialogue
 SaveImage.FileName:=filename+'.'+Image.FormatExt;
 SaveImage.DefaultExt:=Image.FormatExt;
 //Show the dialogue
 If SaveImage.Execute then
  //Save the image
  Image.SaveToFile(SaveImage.FileName);
end;

//Attribute has been changed
procedure TMainForm.AttributeChangeClick(Sender: TObject);
var
 att,filepath: AnsiString;
begin
 if not DoNotUpdate then
 begin
  att:='';
   //Attributes
   if cb_ownerwrite.Checked    then att:=att+'W';
   if cb_ownerread.Checked     then att:=att+'R';
   if cb_ownerlocked.Checked   then att:=att+'L';
   if cb_ownerexecute.Checked  then att:=att+'E';
   if cb_publicwrite.Checked   then att:=att+'w';
   if cb_publicread.Checked    then att:=att+'r';
   if cb_publicexecute.Checked then att:=att+'e';
   if cb_private.Checked       then att:=att+'P';
   //Get the file path
   filepath:=GetFilePath(DirList.Selected);
   //Update the attributes for the file
   if not Image.UpdateAttributes(filepath,att) then
   begin
    //If unsuccessful, revert back.
    DoNotUpdate:=True;
    TCheckbox(Sender).Checked:=not TCheckbox(Sender).Checked;
    DoNotUpdate:=False;
   end;
 end;
end;

//Get full file path from selected node
function TMainForm.GetFilePath(Node: TTreeNode): AnsiString;
begin
 //Make sure that the node exists
 if Node<>nil then
 begin
  //Start with the text in the node (i.e the filename)
  Result:=Node.Text;
  //If it has a parent, then add this and move up a level, until we reach the root
  while Node.Parent<>nil do
  begin
   Node:=Node.Parent;
   Result:=Node.Text+Image.DirSep+Result;
  end;
 end;
end;

//Delete file
procedure TMainForm.DeleteFile1Click(Sender: TObject);
var
 filepath: AnsiString;
 i: Integer;
 R: Boolean;
begin
 //Result of the confirmation - assumed Yes for now
 R:=True;
 //For mulitple deletes, ensure that the user really wants to
 if DirList.SelectionCount>1 then
   R:=MessageDlg('Delete '+IntToStr(DirList.SelectionCount)+' files?',
                 mtInformation,[mbYes, mbNo],0)=mrYes;
 //If user does, or single file, continue
 if R then
  //Go through all the selections (or the only one)
  for i:=0 to DirList.SelectionCount-1 do
  begin
   //Get the full path to the file
   filepath:=GetFilePath(DirList.Selections[i]);
   //If singular, check if the user wants to
   if DirList.SelectionCount=1 then
    R:=MessageDlg('Delete '+filepath+'?',mtInformation,[mbYes, mbNo],0)=mrYes;
   //If so, then delete
   if R then
    if Image.DeleteFile(filepath) then
    begin
     //Now update the node and filedetails panel
     DirList.Selections[i].Delete;
     ResetFileFields;
    end;
  end;
end;

//User has double clicked on the DirList box
procedure TMainForm.DirListDblClick(Sender: TObject);
var
 Node: TTreeNode;
begin
 //Get the selected Node (currently only a single node can be selected)
 Node:=DirList.Selected;
 //Only act on it if there is one selected
 if Node<>nil then
  //If it is not a directory, then proceed to download it, otherwise the system
  //will just expand the node
  if not (TMyTreeNode(Node).IsDir) then
   btn_downloadClick(Sender);
end;

//Rename menu item has been clicked
procedure TMainForm.RenameFile1Click(Sender: TObject);
begin
 //Make sure we're not dealing with the root
 if DirList.Selected.Parent<>nil then
 begin
  //Save the path and name before they get edited
  PathBeforeEdit:=GetFilePath(DirList.Selected);
  NameBeforeEdit:=DirList.Selected.Text;
  //Set the node to edit mode
  DirList.Selected.EditText;
 end;
end;

//Can we rename this node or not?
procedure TMainForm.DirListEditing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
 //Set the node to edit mode, if not the root
 AllowEdit:=Node.Parent<>nil;
 //Save the path and name before they get edited
 PathBeforeEdit:=GetFilePath(Node);
 NameBeforeEdit:=Node.Text;
end;

//Rename file/directory
procedure TMainForm.DirListEditingEnd(Sender: TObject; Node: TTreeNode;
 Cancel: Boolean);
var
 newfilename: AnsiString;
begin
 newfilename:=Node.Text;
 if not Cancel then
  //Rename the file
  if not Image.RenameFile(PathBeforeEdit,newfilename) then
   //Revert if it cannot be renamed
   Node.Text:=NameBeforeEdit
  else
  begin
   //Otherwise change the text on the tree and the file details panel
   Node.Text:=newfilename;
   lb_Filename.Caption:=newfilename;
  end;
 //Reset the tracking variables
 PathBeforeEdit:='';
 NameBeforeEdit:='';
end;

//Reset the label fields for file info
procedure TMainForm.ResetFileFields;
begin
 DoNotUpdate         :=True;
 lb_FileName.Caption :='';
 lb_filetype.Caption :='';
 lb_loadaddr.Caption :='';
 lb_execaddr.Caption :='';
 lb_length.Caption   :='';
 lb_timestamp.Caption:='';
 lb_parent.Caption   :='';
 lb_title.Caption    :='';
 lb_location.Caption :='';
 img_FileType.Picture.Bitmap:=nil;
 //Disable the access tick boxes
 cb_ownerwrite.Enabled    :=False;
 cb_ownerread.Enabled     :=False;
 cb_ownerlocked.Enabled   :=False;
 cb_ownerexecute.Enabled  :=False;
 cb_publicwrite.Enabled   :=False;
 cb_publicread.Enabled    :=False;
 cb_publicexecute.Enabled :=False;
 cb_private.Enabled       :=False;
 //And untick them
 cb_ownerwrite.Checked    :=False;
 cb_ownerread.Checked     :=False;
 cb_ownerlocked.Checked   :=False;
 cb_ownerexecute.Checked  :=False;
 cb_publicwrite.Checked   :=False;
 cb_publicread.Checked    :=False;
 cb_publicexecute.Checked :=False;
 cb_private.Checked       :=False;
 DoNotUpdate   :=False;
end;

//Clear the search edit boxes
procedure TMainForm.ResetSearchFields;
begin
 lb_searchresults.Clear;
 ed_filenamesearch.Text:='';
 ed_lengthsearch.Text:='';
 searchresultscount.Caption:='Number of results found: '+IntToStr(lb_searchresults.Count);
end;

//Search for files
procedure TMainForm.sb_searchClick(Sender: TObject);
var
 search : TDirEntry;
 results: TSearchResults;
 t1,t2  : AnsiString;
 i      : Integer;
begin
 ResetDirEntry(search);
 SetLength(results,0);
 //Get the search criteria: you can search on more fields than this - these three
 //are just used as a demonstration. To search on more fields, just enter them
 //into the appropriate field in the 'search' structure - blank or zero fields
 //are not used in the search.
 search.Filename:=ed_filenamesearch.Text;
 search.Filetype:=ed_filetypesearch.Text;
 //Validate that the length entered is a hex number
 t1:=UpperCase(ed_lengthsearch.Text);
 if Length(t1)>0 then
 begin
  t2:='0x';
  for i:=1 to Length(t1) do
   if ((ord(t1[i])>47) and (ord(t1[i])<58))
   or ((ord(t1[i])>64) and (ord(t1[i])<71)) then
    t2:=t2+t1[i];
  search.Length:=StrToInt(t2);
 end;
 results:=Image.FileSearch(search);
 lb_searchresults.Clear;
 if Length(results)>0 then
  for i:=0 to Length(results)-1 do
   lb_searchresults.Items.Add(results[i].Parent+'.'+results[i].Filename);
 searchresultscount.Caption:='Number of results found: '+IntToStr(lb_searchresults.Count);
end;

//Converts a number into a string with trailing 'Bytes', 'KB', etc.
function TMainForm.ConvertToKMG(size: Int64): AnsiString;
var
 new_size_int : Int64; //Int64 will allow for huge disc sizes
 new_size_dec,
 level,
 multiplier   : Integer;
const
 sizes: array[1..6] of AnsiString = ('Bytes','KB','MB','GB','TB','EB');
begin
 //Default is in bytes
 Result:=IntToStr(size)+' '+sizes[1];
 //How far through the array
 level:=0;
 //Current multiplier - KB is 1024 bytes, but MB is 1000 KB...odd, I know!
 multiplier:=1024;
 //We just do this as the first thing we do is divide
 new_size_int:=size*multiplier;
 repeat //we could use a While Do loop and avoid the pre-multiplying above
  inc(level); //Next level, or entry into the array
  //There are 1000KB per MB, 1000MB per GB, etc. but 1024 bytes per KB, etc.
  if level>2 then multiplier:=1000;
  //Work out the remainder, as a decimal to three decimal places
  new_size_dec:=Round(((new_size_int mod multiplier)/multiplier)*1000);
  //Reduce the size to the next smaller multiple
  new_size_int:=new_size_int div multiplier;
  //and repeat until we are smaller than the current multiple, or out of choices
 until (new_size_int<multiplier) or (level=High(sizes));
 //If level is valid
 if level<=High(sizes) then
 begin
  //First the major, whole number, portion
  Result:=IntToStr(new_size_int);
  //Then the decimal portion, but only if there is one
  if new_size_dec>0 then
  begin
   //Add an extra zero, which will be removed
   Result:=Result+'.'+IntToStr(new_size_dec)+'0';
   //Now remove all the surplus zeros
   repeat
    Result:=Copy(Result,1,Length(Result)-1);
   until Result[Length(Result)]<>'0';
  end;
  //And finally return the result, with the unit
  Result:=Result+' '+sizes[level];
 end;
end;

//Converts Int64 to string, adding in the thousand separator ','
function TMainForm.IntToStrComma(size: Int64): AnsiString;
begin
 Result:=Format('%.0n',[1.0*size]);
end;

//Convert BBC to Windows filename
procedure TMainForm.BBCtoWin(var f: AnsiString);
var
 i: Integer;
begin
 for i:=1 to Length(f) do
 begin
  if f[i]='/' then f[i]:='.';
  if f[i]='?' then f[i]:='#';
  if f[i]='<' then f[i]:='$';
  if f[i]='>' then f[i]:='^';
  if f[i]='+' then f[i]:='&';
  if f[i]='=' then f[i]:='@';
  if f[i]=';' then f[i]:='%';
 end;
end;

//Validate a filename for Windows
procedure TMainForm.ValidateFilename(var f: AnsiString);
var
 i: Integer;
begin
 for i:=1 to Length(f) do
  if (f[i]='\')
  or (f[i]='/')
  or (f[i]=':')
  or (f[i]='*')
  or (f[i]='?')
  or (f[i]='"')
  or (f[i]='<')
  or (f[i]='>')
  or (f[i]='|') then
   f[i]:=' ';
end;

end.
