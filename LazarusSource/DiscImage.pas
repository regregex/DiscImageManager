unit DiscImage;

//This project is now covered by the GNU GPL v3 licence

{$MODE objFPC}

interface

uses Classes;

{$M+}

type
//Define the TDIByteArray - saves using the System.Types unit for TByteDynArray
 TDIByteArray = array of Byte;
//Free space map
 TTrack = array of TDIByteArray; //TDIByteArray representing the sectors
 TSide  = array of TTrack;      //Sides
//Define the records to hold the catalogue
 TDirEntry     = record     //Not all fields are used on all formats
  Parent,                   //Complete path for parent directory (ALL)
  Filename,                 //Filename (ALL)
  Attributes,               //File attributes (ADFS/DFS/D64/D71/D81/AmigaDOS)
  Filetype,                 //Full name filetype (ADFS/D64/D71/D81)
  ShortFileType: AnsiString;//Filetype shortname (ADFS/D64/D71/D81)
  LoadAddr,                 //Load Address (ADFS/DFS)
  ExecAddr,                 //Execution Address (ADFS/DFS)
  Length,                   //Total length (ALL)
  Side,                     //Side of disc of location of data (DFS)
  Track,                    //Track of location of data (D64/D71/D81)
  DataFile,                 //Reserved for use by Repton Map Display
  ImageAddress: Cardinal;   //Reserved for use by Repton Map Display
  Sector,                   //Sector of disc of location of data (DFS/D64/D71/D81/AmigaDOS file)
                            //Sector of disc of location of header (AmigaDOS directory)
                            //Address of location of data (ADFS S/M/L)
                            //Indirect disc address of data (ADFS D/E/F/E+/F+)
  DirRef      : Integer;    //Reference to directory, if directory (ADFS/AmigaDOS)
  TimeStamp   : TDateTime;  //Timestamp (ADFS D/E/E+/F/F+)
  EOR         : Byte;       //Reserved for use by Repton Map Display
 end;
 TSearchResults =array of TDirEntry;
 TDir          = record
  Directory,                       //Directory name (ALL)
  Title       : AnsiString;        //Directory title (DFS/ADFS)
  Entries     : array of TDirEntry;//Entries (above)
  Broken      : Boolean;           //Flag if directory is broken (ADFS)
  ErrorCode   : Byte;              //Used to indicate error for broken directory (ADFS)
 end;
 TDisc         = array of TDir;
//For retrieving the ADFS E/F fragment information
 TFragment     = record
  Offset,
  Length      : Cardinal;
 end;
 TFragmentArray= array of TFragment;
 procedure ResetDirEntry(var Entry: TDirEntry);
 procedure RemoveTopBit(var title: AnsiString);
const
 //When the change of number of sectors occurs on Commodore discs
 CDRhightrack : array[0..8] of Integer = (71,66,60,53,36,31,25,18, 1);
 //Number of sectors per track
 CDRnumsects  : array[0..7] of Integer = (17,18,19,21,17,18,19,21);
//The class definition
type
 TDiscImage    = Class
 private
  FDisc         : TDisc;        //Container for the entire catalogue
  Fdata         : TDIByteArray; //Container for the image to be loaded into
  FDSD,                         //Double sided flag (Acorn DFS)
  FMap,                         //Old/New Map flag (Acorn ADFS) OFS/FFS (Amiga)
  FBootBlock    : Boolean;      //Is disc an AmigaDOS Kickstart?
  secsize,                      //Sector Size
  bpmb,                         //Bits Per Map Bit (Acorn ADFS New)
  nzones,                       //Number of zones (Acorn ADFS New)
  root,                         //Root address
  bootmap,                      //Offset of the map (Acorn ADFS)
  zone_spare,                   //Spare bits between zones (Acorn ADFS New)
  format_vers,                  //Format version (Acorn ADFS New)
  root_size,                    //Size of the root directory (Acorn ADFS New)
  disc_id,                      //Disc ID (Acorn ADFS)
  emuheader     : Cardinal;     //Allow for any headers added by emulators
  disc_size,                    //Size of disc in bytes
  free_space    : Int64;        //Free space remaining
  FFormat,                      //Format of the image
  secspertrack,                 //Number of sectors per track
  heads,                        //Number of heads (Acorn ADFS New)
  density,                      //Density (Acorn ADFS New)
  idlen,                        //Length of fragment ID in bits (Acorn ADFS New)
  skew,                         //Head skew (Acorn ADFS New)
  lowsector,                    //Lowest sector number (Acorn ADFS New)
  disctype,                     //Type of disc
  FDirType,                     //Directory Type (Acorn ADFS)
  share_size,                   //Share size (Acorn ADFS New)
  big_flag      : Byte;         //Big flag (Acorn ADFS New)
  disc_name,                    //Disc title(s)
  root_name,                    //Root title
  imagefilename : AnsiString;   //Filename of the disc image
  dir_sep       : Char;         //Directory Separator
  free_space_map: TSide;        //Free Space Map
  bootoption    : TDIByteArray; //Boot Option(s)
  procedure ResetVariables;
  function ReadString(ptr,term: Integer): AnsiString; overload;
  function ReadString(ptr,term: Integer;control: Boolean): AnsiString; overload;
  procedure RemoveSpaces(var s: AnsiString);
  procedure RemoveControl(var s: AnsiString);
  function FormatToString: AnsiString;
  function FormatToExt: AnsiString;
  function ReadBits(offset,start,length: Cardinal): Cardinal;
  function IsBitSet(v,b: Integer): Boolean;
  function ConvertTimeDate(filedatetime: Int64): TDateTime;
  function Read32b(offset: Cardinal): Cardinal; overload;
  function Read32b(offset: Cardinal; bigendian: Boolean): Cardinal; overload;
  function Read24b(offset: Cardinal): Cardinal; overload;
  function Read24b(offset: Cardinal; bigendian: Boolean): Cardinal; overload;
  function Read16b(offset: Cardinal): Word; overload;
  function Read16b(offset: Cardinal; bigendian: Boolean): Word; overload;
  function ReadByte(offset: Cardinal): Byte;
  procedure Write32b(value, offset: Cardinal); overload;
  procedure Write32b(value, offset: Cardinal; bigendian: Boolean); overload;
  procedure Write24b(value, offset: Cardinal); overload;
  procedure Write24b(value, offset: Cardinal; bigendian: Boolean); overload;
  procedure Write16b(value: Word; offset: Cardinal); overload;
  procedure Write16b(value: Word; offset: Cardinal; bigendian: Boolean); overload;
  procedure WriteByte(value: Byte; offset: Cardinal);
  function ROR13(v: Cardinal): Cardinal;
  procedure ResetDir(var Entry: TDir);
  function MapFlagToByte: Byte;
  function MapTypeToString: AnsiString;
  function DirTypeToString: AnsiString;
  function GeneralChecksum(offset,length,chkloc,start: Cardinal;carry: Boolean): Cardinal;
  //ADFS Routines
  function ID_ADFS: Boolean;
  function ReadADFSDir(dirname: AnsiString; sector: Cardinal): TDir;
  function CalculateADFSDirCheck(sector,EndOfChk,tail,dirsize: Cardinal): Byte;
  function NewDiscAddrToOffset(addr: Cardinal): TFragmentArray;
  function OldDiscAddrToOffset(disc_addr: Cardinal): Cardinal;
  function OffsetToOldDiscAddr(offset: Cardinal): Cardinal;
  function ByteChecksum(offset,size: Cardinal): Byte;
  function ReadADFSDisc: TDisc;
  procedure ADFSFreeSpaceMap;
  procedure ADFSFillFreeSpaceMap(address: Cardinal;usage: Byte);
  function FormatADFS(minor: Byte): TDisc;
  function UpdateADFSDiscTitle(title: AnsiString): Boolean;
  function UpdateADFSBootOption(option: Byte): Boolean;
  function WriteADFSFile(var file_details: TDirEntry;var buffer: TDIByteArray): Integer;
  function CreateADFSDirectory(var dirname,parent,attributes: AnsiString): Integer;
  procedure UpdateADFSCat(directory: AnsiString);
  function UpdateADFSFileAttributes(filename,attributes: AnsiString): Boolean;
  function ValidateADFSFilename(filename: AnsiString): AnsiString;
  function RetitleADFSDirectory(filename,newtitle: AnsiString): Boolean;
  function RenameADFSFile(oldfilename: AnsiString;var newfilename: AnsiString):Boolean;
  procedure ConsolodateADFSFreeSpaceMap;
  function DeleteADFSFile(filename: AnsiString):Boolean;
  //DFS Routines
  function ID_DFS: Boolean;
  function ReadDFSDisc: TDisc;
  procedure DFSFreeSpaceMap(LDisc: TDisc);
  function ConvertSector(address,side: Integer): Integer;
  function WriteDFSFile(file_details: TDirEntry;var buffer: TDIByteArray): Integer;
  procedure UpdateDFSCat(side: Integer);
  function ValidateDFSFilename(filename: AnsiString): AnsiString;
  function RenameDFSFile(oldfilename: AnsiString;var newfilename: AnsiString):Boolean;
  function DeleteDFSFile(filename: AnsiString):Boolean;
  function UpdateDFSFileAttributes(filename,attributes: AnsiString): Boolean;
  function FormatDFS(minor,tracks: Byte): TDisc;
  function UpdateDFSDiscTitle(title: AnsiString;side: Byte): Boolean;
  function UpdateDFSBootOption(option,side: Byte): Boolean;
  //Commodore 1541/1571/1581 Routines
  function ID_CDR: Boolean;
  function ConvertDxxTS(format,track,sector: Integer): Integer;
  function ReadCDRDisc: TDisc;
  function FormatCDR(minor: Byte): TDisc;
  procedure CDRFreeSpaceMap;
  function UpdateCDRDiscTitle(title: AnsiString): Boolean;
  function WriteCDRFile(file_details: TDirEntry;var buffer: TDIByteArray): Integer;
  function RenameCDRFile(oldfilename: AnsiString;var newfilename: AnsiString):Boolean;
  function DeleteCDRFile(filename: AnsiString):Boolean;
  function UpdateCDRFileAttributes(filename,attributes: AnsiString): Boolean;
  //Sinclair Spectrum +3/Amstrad Routines
  function ID_Sinclair: Boolean;
  function ReadSinclairDisc: TDisc;
  function FormatSpectrum(minor: Byte): TDisc;
  function WriteSpectrumFile(file_details: TDirEntry;var buffer: TDIByteArray): Integer;
  function RenameSpectrumFile(oldfilename: AnsiString;var newfilename: AnsiString):Boolean;
  function DeleteSinclairFile(filename: AnsiString):Boolean;
  function UpdateSinclairFileAttributes(filename,attributes: AnsiString): Boolean;
  function UpdateSinclairDiscTitle(title: AnsiString): Boolean;
  //Commodore Amiga Routines
  function ID_Amiga: Boolean;
  function ReadAmigaDisc: TDisc;
  function ReadAmigaDir(dirname: AnsiString; offset: Cardinal): TDir;
  function AmigaBootChecksum(offset: Cardinal): Cardinal;
  function AmigaChecksum(offset: Cardinal): Cardinal;
  function FormatAmiga(minor: Byte): TDisc;
  function WriteAmigaFile(var file_details: TDirEntry;var buffer: TDIByteArray): Integer;
  function CreateAmigaDirectory(var dirname,parent,attributes: AnsiString): Integer;
  function RetitleAmigaDirectory(filename, newtitle: AnsiString): Boolean;
  function RenameAmigaFile(oldfilename: AnsiString;var newfilename: AnsiString):Boolean;
  function DeleteAmigaFile(filename: AnsiString):Boolean;
  function UpdateAmigaFileAttributes(filename,attributes: AnsiString): Boolean;
  function UpdateAmigaDiscTitle(title: AnsiString): Boolean;
 published
  //Methods
  constructor Create;
  procedure LoadFromFile(filename: AnsiString);
  procedure LoadFromStream(F: TStream);
  procedure SaveToFile(filename: AnsiString);
  procedure SaveToStream(F: TStream);
  function Format(major,minor,tracks: Byte): Boolean;
  function ExtractFile(filename: AnsiString; var buffer: TDIByteArray): Boolean;
  function ExtractFileToStream(filename: AnsiString;F: TStream): Boolean;
  function WriteFile(var file_details: TDirEntry; var buffer: TDIByteArray): Integer;
  function WriteFileFromStream(var file_details: TDirEntry;F: TStream): Integer;
  function FileExists(filename: AnsiString; var Ref: Cardinal): Boolean;
  function ReadDiscData(addr,count,side: Cardinal; var buffer): Boolean;
  function ReadDiscDataToStream(addr,count,side: Cardinal; F: TStream): Boolean;
  function WriteDiscData(addr,side: Cardinal;var buffer: TDIByteArray; count: Cardinal): Boolean;
  function WriteDiscDataFromStream(addr,side: Cardinal; F: TStream): Boolean;
  function FileSearch(search: TDirEntry): TSearchResults;
  function RenameFile(oldfilename: AnsiString;var newfilename: AnsiString): Boolean;
  function DeleteFile(filename: AnsiString): Boolean;
  function MoveFile(filename, directory: AnsiString): Integer;
  function CopyFile(filename, directory: AnsiString): Integer;
  function UpdateAttributes(filename,attributes: AnsiString): Boolean;
  function UpdateDiscTitle(title: AnsiString;side: Byte): Boolean;
  function UpdateBootOption(option,side: Byte): Boolean;
  function CreateDirectory(var filename,parent,attributes: AnsiString): Integer;
  function RetitleDirectory(var filename,newtitle: AnsiString): Boolean;
  //Properties
  property Disc:                TDisc        read FDisc;
  property FormatString:        AnsiString   read FormatToString;
  property FormatNumber:        Byte         read FFormat;
  property FormatExt:           AnsiString   read FormatToExt;
  property Title:               AnsiString   read disc_name;
  property DiscSize:            Int64        read disc_size;
  property FreeSpace:           Int64        read free_space;
  property DoubleSided:         Boolean      read FDSD;
  property MapType:             Byte         read MapFlagToByte;
  property DirectoryType:       Byte         read FDirType;
  property MapTypeString:       AnsiString   read MapTypeToString;
  property DirectoryTypeString: AnsiString   read DirTypeToString;
  property DirSep:              Char         read dir_sep;
  property Filename:            AnsiString   read imagefilename;
  property FreeSpaceMap:        TSide        read free_space_map;
  property BootOpt:             TDIByteArray read bootoption;
  property RootAddress:         Cardinal     read root;
 public
  destructor Destroy; override;
 End;

implementation

uses
 SysUtils,DateUtils;

{-------------------------------------------------------------------------------
Reset a TDirEntry to blank (not part of the TDiscImage class)
-------------------------------------------------------------------------------}
procedure ResetDirEntry(var Entry: TDirEntry);
begin
 with Entry do
 begin
  Parent       :='';
  Filename     :='';
  Attributes   :='';
  Filetype     :='';
  ShortFiletype:='';
  LoadAddr     :=$0000;
  ExecAddr     :=$0000;
  Length       :=$0000;
  Side         :=$0000;
  Track        :=$0000;
  DataFile     :=$0000;
  ImageAddress :=$0000;
  Sector       :=$0000;
  DirRef       :=$0000;
  TimeStamp    :=0;
  EOR          :=$00;
 end;
end;

{-------------------------------------------------------------------------------
Remove top bit set characters
-------------------------------------------------------------------------------}
procedure RemoveTopBit(var title: AnsiString);
var
 t: Integer;
begin
 for t:=1 to Length(title) do title[t]:=chr(ord(title[t])AND$7F);
end;

//++++++++++++++++++ Class definition starts here ++++++++++++++++++++++++++++++

{-------------------------------------------------------------------------------
Reset all the variables
-------------------------------------------------------------------------------}
procedure TDiscImage.ResetVariables;
begin
 //Default values
 SetLength(FDisc,0);
 FDSD          :=False;
 FMap          :=False;
 FBootBlock    :=True;
 secsize       :=$0000;
 bpmb          :=$0000;
 nzones        :=$0000;
 root          :=$0000;
 bootmap       :=$0000;
 zone_spare    :=$0000;
 format_vers   :=$0000;
 root_size     :=$0000;
 disc_id       :=$0000;
 disc_size     :=$0000;
 free_space    :=$0000;
 FFormat       :=$FF;
 secspertrack  :=$00;
 heads         :=$00;
 density       :=$00;
 idlen         :=$00;
 skew          :=$00;
 SetLength(bootoption,0);
 lowsector     :=$00;
 disctype      :=$00;
 FDirType      :=$FF;
 share_size    :=$00;
 big_flag      :=$00;
 disc_name     :='';
 emuheader     :=$0000;
 dir_sep       :='.';
 root_name     :='$';
 imagefilename :='';
 SetLength(free_space_map,0);
end;

{-------------------------------------------------------------------------------
Extract a string from ptr to the next chr(term) or length(-term)
-------------------------------------------------------------------------------}
function TDiscImage.ReadString(ptr,term: Integer): AnsiString;
begin
 Result:=ReadString(ptr,term,True);
end;
function TDiscImage.ReadString(ptr,term: Integer;control: Boolean): AnsiString;
var
 x : Integer;
 c,
 r : Byte;
begin
 //Counter
 x:=0;
 //Dummy result
 Result:='';
 //Are we excluding control characters?
 if control then c:=32 else c:=0;
 //Start with the first byte (we pre-read it to save multiple reads)
 r:=ReadByte(ptr+x);
 while (r>=c) and //Test for control character
       (((r<>term) and (term>=0)) or //Test for terminator character
        ((x<abs(term)) and (term<0))) do //Test for string length
 begin
  Result:=Result+chr(r); //Add it to the string
  inc(x);                //Increase the counter
  r:=ReadByte(ptr+x);    //Read the next character
 end;
end;

{-------------------------------------------------------------------------------
Removes trailing spaces from a string
-------------------------------------------------------------------------------}
procedure TDiscImage.RemoveSpaces(var s: AnsiString);
var
 x: Integer;
begin
 //Start at the end
 x:=Length(s);
 if x>0 then
 begin
  while (s[x]=' ') and (x>0) do //Continue while the last character is a space
   dec(x);       //Move down the string
  s:=Copy(s,1,x);//Finally, remove the spaces
 end;
end;

{-------------------------------------------------------------------------------
Removes control characters from a string
-------------------------------------------------------------------------------}
procedure TDiscImage.RemoveControl(var s: AnsiString);
var
 x: Integer;
 o: AnsiString;
begin
 //New String
 o:='';
 //Iterate through the old string
 for x:=1 to Length(s) do
  //Only add the character to the new string if it is not a control character
  if ord(s[x])>31 then o:=o+s[x];
 //Change the old string to the new string
 s:=o;
end;

{-------------------------------------------------------------------------------
Convert a format byte to a string
-------------------------------------------------------------------------------}
function TDiscImage.FormatToString: AnsiString;
const
 FS  : array[0..4] of AnsiString = ('DFS',
                                'Acorn ADFS',
                                'Commodore',
                                'Sinclair Spectrum +3/Amstrad',
                                'Commodore Amiga');
 SUB : array[0..4] of array[0..15] of AnsiString =
 (('Acorn SSD','Acorn DSD','Watford SSD','Watford DSD','','','','','','','','','','','',''),
  ('S','M','L','D','E','E+','F','F+','','','','','','','','Hard Disc'),
  ('1541','1571','1581','','','','','','','','','','','','',''),
  ('','Extended','','','','','','','','','','','','','',''),
  ('DD','HD','','','','','','','','','','','','','','Hard Disc'));
begin
 if FFormat<>$FF then
 begin
  Result:= FS[FFormat DIV $10]+' '
         +SUB[FFormat DIV $10,FFormat MOD $10];
 end
 else Result:='unknown';
end;

{-------------------------------------------------------------------------------
Convert a format byte to an extension
-------------------------------------------------------------------------------}
function TDiscImage.FormatToExt: AnsiString;
const
 EXT : array[0..4] of array[0..15] of AnsiString =
 (('ssd','dsd','ssd','dsd','','','','','','','','','','','',''),
  ('ads','adm','adl','adf','adf','adf','adf','adf','','','','','','','','hdf'),
  ('d64','d71','d81','','','','','','','','','','','','',''),
  ('','dsk','','','','','','','','','','','','','',''),
  ('adf','adf','','','','','','','','','','','','','','hdf'));
begin
 if FFormat<>$FF then
 begin
  Result:=EXT[FFormat DIV $10,FFormat MOD $10];
 end
 else Result:='unk';
end;

{-------------------------------------------------------------------------------
Read upto 32 bits of data from the buffer, starting at offset(bytes)+start(bits)
-------------------------------------------------------------------------------}
function TDiscImage.ReadBits(offset,start,length: Cardinal): Cardinal;
var
 start_byte,
 start_bit,
 bit,b,prev : Cardinal;
 lastbyte   : Byte;
begin
 //Reset the result
 Result:=0;
 //If the length is 0, nothing to read. Cardinals are 32 bits
 //(we could use Integers, but these are signed)
 if (length>0) and (length<33) then
 begin
  prev:=$FFFFFFFF;
  lastbyte:=0;
  //Iterate through the required number of bits
  for bit:=0 to length-1 do
  begin
   //Work out the byte offset, and the bit within
   start_byte:=(start+bit) div 8;
   start_bit :=(start+bit) mod 8;
   //And increase the result with the extracted bit, shifted right to account
   //for final position
   if prev<>offset+start_byte then
   begin
    //To save re-reading the same byte over and over
    prev:=offset+start_byte;
    lastbyte:=ReadByte(prev);
   end;
   b:=(lastbyte AND (1 shl start_bit))shr start_bit;
   inc(Result,b shl bit);
  end;
 end;
end;

{-------------------------------------------------------------------------------
Check to see if bit b is set in word v
-------------------------------------------------------------------------------}
function TDiscImage.IsBitSet(v,b: Integer): Boolean;
var
 x: Integer;
begin
 Result:=False;
 if (b>=0) and (b<32) then
 begin
  x:=1 shl b;
  Result:=((v AND x)=x);
 end;
end;

{-------------------------------------------------------------------------------
Converts a RISC OS Time/Date to a Delphi TDateTime
-------------------------------------------------------------------------------}
function TDiscImage.ConvertTimeDate(filedatetime: Int64): TDateTime;
var
 epoch      : TDateTime;
 riscosdays : Int64;
const
 dayincsec = 8640000; //24*3600*100 centi seconds = 1 day
begin
 //RISC OS counts from 00:00:00 1st January 1900
 epoch:=EncodeDateTime(1900,01,01,00,00,00,000);
 //Number of days in file timestamp
 riscosdays:=filedatetime div dayincsec;
 //Convert to Delphi TDateTime
 Result:=riscosdays+epoch                                 //Whole part
        +((filedatetime-riscosdays*dayincsec)/dayincsec); //Fraction part
end;

{-------------------------------------------------------------------------------
Read in 4 bytes (word)
-------------------------------------------------------------------------------}
function TDiscImage.Read32b(offset: Cardinal): Cardinal;
begin
 Result:=Read32b(offset,False);
end;
function TDiscImage.Read32b(offset: Cardinal; bigendian: Boolean): Cardinal;
begin
 Result:=$FFFFFFFF; //Default value
 //Big Endian
 if bigendian then
  Result:=ReadByte(offset+3)
         +ReadByte(offset+2)*$100
         +ReadByte(offset+1)*$10000
         +ReadByte(offset+0)*$1000000
 else
  //Little Endian
  Result:=ReadByte(offset+0)
         +ReadByte(offset+1)*$100
         +ReadByte(offset+2)*$10000
         +ReadByte(offset+3)*$1000000;
end;

{-------------------------------------------------------------------------------
Read in 3 bytes
-------------------------------------------------------------------------------}
function TDiscImage.Read24b(offset: Cardinal): Cardinal;
begin
 Result:=Read24b(offset,False);
end;
function TDiscImage.Read24b(offset: Cardinal; bigendian: Boolean): Cardinal;
begin
 Result:=$FFFFFF; //Default value
 //Big Endian
 if bigendian then
  Result:=ReadByte(offset+2)
         +ReadByte(offset+1)*$100
         +ReadByte(offset+0)*$10000
 else
  //Little Endian
  Result:=ReadByte(offset+0)
         +ReadByte(offset+1)*$100
         +ReadByte(offset+2)*$10000;
end;

{-------------------------------------------------------------------------------
Read in 2 bytes
-------------------------------------------------------------------------------}
function TDiscImage.Read16b(offset: Cardinal): Word;
begin
 Result:=Read16b(offset,False);
end;
function TDiscImage.Read16b(offset: Cardinal; bigendian: Boolean): Word;
begin
 Result:=$FFFF; //Default value
 //Big Endian
 if bigendian then
  Result:=ReadByte(offset+1)
         +ReadByte(offset+0)*$100
 else
  //Little Endian
  Result:=ReadByte(offset+0)
         +ReadByte(offset+1)*$100;
end;

{-------------------------------------------------------------------------------
Read in a byte
-------------------------------------------------------------------------------}
function TDiscImage.ReadByte(offset: Cardinal): Byte;
begin
 Result:=$FF; //Default value
 //Compensate for interleaving (ADFS L)
 if FFormat=$12 then offset:=OldDiscAddrToOffset(offset);
 //Compensate for emulator header
 inc(offset,emuheader);
 //If we are inside the data, read the byte
 if offset<Cardinal(Length(Fdata)) then
  Result:=Fdata[offset];
end;

{-------------------------------------------------------------------------------
Write 4 bytes (word)
-------------------------------------------------------------------------------}
procedure TDiscImage.Write32b(value, offset: Cardinal);
begin
 Write32b(value,offset,False);
end;
procedure TDiscImage.Write32b(value, offset: Cardinal; bigendian: Boolean);
begin
 if bigendian then
 begin
  //Big Endian
  WriteByte( value mod $100             ,offset+3);
  WriteByte((value div $100)    mod $100,offset+2);
  WriteByte((value div $10000)  mod $100,offset+1);
  WriteByte((value div $1000000)mod $100,offset+0);
 end
 else
 begin
  //Little Endian
  WriteByte( value mod $100,             offset+0);
  WriteByte((value div $100)    mod $100,offset+1);
  WriteByte((value div $10000)  mod $100,offset+2);
  WriteByte((value div $1000000)mod $100,offset+3);
 end;
end;

{-------------------------------------------------------------------------------
Write 3 bytes
-------------------------------------------------------------------------------}
procedure TDiscImage.Write24b(value, offset: Cardinal);
begin
 Write24b(value,offset,False);
end;
procedure TDiscImage.Write24b(value,offset: Cardinal; bigendian: Boolean);
begin
 if bigendian then
 begin
  //Big Endian
  WriteByte( value mod $100             ,offset+2);
  WriteByte((value div $100)    mod $100,offset+1);
  WriteByte((value div $10000)  mod $100,offset+0);
 end
 else
 begin
  //Little Endian
  WriteByte( value mod $100             ,offset+0);
  WriteByte((value div $100)    mod $100,offset+1);
  WriteByte((value div $10000)  mod $100,offset+2);
 end;
end;

{-------------------------------------------------------------------------------
Write 2 bytes
-------------------------------------------------------------------------------}
procedure TDiscImage.Write16b(value: Word; offset: Cardinal);
begin
 Write16b(value,offset,False);
end;
procedure TDiscImage.Write16b(value: Word; offset: Cardinal; bigendian: Boolean);
begin
 if bigendian then
 begin
  //Big Endian
  WriteByte( value mod $100             ,offset+1);
  WriteByte((value div $100)    mod $100,offset+0);
 end
 else
 begin
  //Little Endian
  WriteByte( value mod $100             ,offset+0);
  WriteByte((value div $100)    mod $100,offset+1);
 end;
end;

{-------------------------------------------------------------------------------
Write byte
-------------------------------------------------------------------------------}
procedure TDiscImage.WriteByte(value: Byte; offset: Cardinal);
begin
 //Compensate for interleaving (ADFS L)
 if FFormat=$12 then offset:=OldDiscAddrToOffset(offset);
 //Compensate for emulator header
 inc(offset,emuheader);
 //Write the byte
 if offset<Cardinal(Length(Fdata)) then
  Fdata[offset]:=value;
end;

{-------------------------------------------------------------------------------
Rotate Right 13 bits
-------------------------------------------------------------------------------}
function TDiscImage.ROR13(v: Cardinal): Cardinal;
begin
 //Shift right 13 bits OR shift left 32-13=19 bits
 Result:=(v shr 13) OR (v shl 19);
end;

{-------------------------------------------------------------------------------
Reset a TDir to blank
-------------------------------------------------------------------------------}
procedure TDiscImage.ResetDir(var Entry: TDir);
begin
 with Entry do
 begin
  Directory:='';
  Title    :='';
  SetLength(Entries,0);
  Broken   :=False;
  ErrorCode:=$00;
 end;
end;

{-------------------------------------------------------------------------------
Convert the Map flag to Map Type
-------------------------------------------------------------------------------}
function TDiscImage.MapFlagToByte: Byte;
begin
 Result:=$FF;               //Default value for non-ADFS
 if FFormat div $10=$1 then //Is it ADFS?
 begin
  Result:=$00;              // ADFS Old Map
  if FMap then Result:=$01; // ADFS New Map
 end;
 if FFormat div $10=$4 then //Is it Amiga?
 begin
  Result:=$02;              // AmigaDOS OFS
  if FMap then Result:=$03; // AmigaDOS FFS
 end;
end;

{-------------------------------------------------------------------------------
Convert the Map flag to String
-------------------------------------------------------------------------------}
function TDiscImage.MapTypeToString: AnsiString;
begin
 Result:='Not ADFS/AmigaDOS';
 case MapFlagToByte of
  $00: Result:='ADFS Old Map';
  $01: Result:='ADFS New Map';
  $02: Result:='AmigaDOS OFS';
  $03: Result:='AmigaDOS FFS';
 end;
end;

{-------------------------------------------------------------------------------
Convert the Directory Type to String
-------------------------------------------------------------------------------}
function TDiscImage.DirTypeToString: AnsiString;
begin
 Result:='Not ADFS/AmigaDOS';
 case FDirType of
  $00: Result:='ADFS Old Directory';
  $01: Result:='ADFS New Directory';
  $02: Result:='ADFS Big Directory';
  $10: Result:='AmigaDOS Directory';
  $11: Result:='AmigaDOS Directory Cache';
 end;
end;

{-------------------------------------------------------------------------------
Calculate Generic checksum - used by AmigaDOS and ADFS New Map checksums
-------------------------------------------------------------------------------}
function TDiscImage.GeneralChecksum(offset,length,chkloc,start: Cardinal;carry: Boolean): Cardinal;
var
 pointer,
 word    : Cardinal;
 acc     : Int64;
begin
 //Reset the accumulator to zero
 acc:=0;
 //Start the offset at 0+offset
 pointer:=start;
 repeat
  //Do not include the checksum itself
  if pointer<>chkloc then
  begin
   //Read the word
   word:=Read32b(offset+pointer,start=0);
   //Add each word to the accumulator
   inc(acc,word);
  end;
  //Move onto the next word
  inc(pointer,4);
  //Until the entire section is done.
 until pointer>=length;
 //Reduce from 64 bits to 32 bits
 word:=(acc MOD $100000000);
 if carry then inc(word,acc DIV $100000000);
 //Add the first word, if skipped, ignoreing the first byte (checksum)
 if start=$4 then
 begin
  inc(word,Read32b(offset) AND $FFFFFF00);
  Result:=((word AND $000000FF)
      XOR ((word AND $0000FF00) shr  8)
      XOR ((word AND $00FF0000) shr 16)
      XOR ((word AND $FF000000) shr 24))AND $FF;
 end
 else Result:=word;
end;

//++++++++++++++++++ Published Methods +++++++++++++++++++++++++++++++++++++++++

{-------------------------------------------------------------------------------
Create the instance
-------------------------------------------------------------------------------}
constructor TDiscImage.Create;
begin
 inherited;
 //This just sets all the global and public variables to zero, or blank.
 ResetVariables;
 SetLength(Fdata,0);
end;

{-------------------------------------------------------------------------------
Free the instance
-------------------------------------------------------------------------------}
destructor TDiscImage.Destroy;
begin
 inherited;
end;

{-------------------------------------------------------------------------------
Load an image from a file (just calls LoadFromStream)
-------------------------------------------------------------------------------}
procedure TDiscImage.LoadFromFile(filename: AnsiString);
var
 FDiscDrive: TFileStream;
begin
 //Only read the file in if it actually exists (or rather, Windows can find it)
 if SysUtils.FileExists(filename) then
 begin
  //Create the stream
  FDiscDrive:=TFileStream.Create(filename,fmOpenRead);
  //Call the procedure to read from the stream
  LoadFromStream(FDiscDrive);
  //Close the stream
  FDiscDrive.Free;
  imagefilename:=filename;
 end;
end;

{-------------------------------------------------------------------------------
Load an image from a stream (e.g. FileStream)
-------------------------------------------------------------------------------}
procedure TDiscImage.LoadFromStream(F: TStream);
begin
 //Blank off the variables
 ResetVariables;
 //Ensure there is enough space in the buffer
 SetLength(Fdata,F.Size);
 //Move to the beginning of the stream
 F.Position:=0;
// UpdateProgress('Loading file');
 //Read the image into the data buffer
 F.Read(Fdata[0],Length(Fdata));
 //This check is done in the ID functions anyway, but we'll do it here also
 if Length(Fdata)>0 then
 begin
  //ID the type of image, from the data contents
  //These need to be ID-ed in a certain order as one type can look like another
  if ID_ADFS     then FDisc:=ReadADFSDisc;    //Acorn ADFS
  if ID_CDR      then FDisc:=ReadCDRDisc;     //Commodore
  if ID_Amiga    then FDisc:=ReadAmigaDisc;   //Amiga
  if ID_DFS      then FDisc:=ReadDFSDisc;     //Acorn DFS
  if ID_Sinclair then FDisc:=ReadSinclairDisc;//Sinclair/Amstrad
  if FFormat=$FF then ResetVariables;
  //Just by the ID process:
  //ADFS 'F' can get mistaken for Commodore
  //Commodore and Amiga can be mistaken for DFS
 end;
end;

{-------------------------------------------------------------------------------
Saves an image to a file
-------------------------------------------------------------------------------}
procedure TDiscImage.SaveToFile(filename: AnsiString);
var
 FDiscDrive: TFileStream;
 ext: AnsiString;
begin
 //Validate the filename
 ext:=ExtractFileExt(filename);
 filename:=LeftStr(filename,Length(filename)-Length(ext));
 filename:=filename+'.'+FormatToExt;
 //Create the stream
 FDiscDrive:=TFileStream.Create(filename,fmCreate);
 //Call the procedure to read from the stream
 SaveToStream(FDiscDrive);
 //Close the stream
 FDiscDrive.Free;
 //Change the image's filename
 imagefilename:=filename;
end;

{-------------------------------------------------------------------------------
Saves an image to a stream
-------------------------------------------------------------------------------}
procedure TDiscImage.SaveToStream(F: TStream);
begin
 //Move to the beginning of the stream
 F.Position:=0;
 //Read the image into the data buffer
 F.Write(Fdata[0],Length(Fdata));
end;

{-------------------------------------------------------------------------------
Create and format a new disc image
-------------------------------------------------------------------------------}
function TDiscImage.Format(major,minor,tracks: Byte): Boolean;
begin
 Result:=False;
 //Make sure the numbers are within bounds
 major :=major MOD $10;
 minor :=minor MOD $10;
 tracks:=tracks MOD 2;
 case major of
  0://Create DFS
   begin
    FDisc:=FormatDFS(minor,tracks);
    Result:=Length(FDisc)>0;
   end;
  1://Create ADFS
   begin
    FDisc:=FormatADFS(minor);
    Result:=Length(FDisc)>0;
   end;
  2://Create Commodore 64/128
   begin
    FDisc:=FormatCDR(minor);
    Result:=Length(FDisc)>0;
   end;
  3://Create Sinclair/Amstrad
   begin
    FDisc:=FormatSpectrum(minor);
    Result:=Length(FDisc)>0;
   end;
  4://Create AmigaDOS
   begin
    FDisc:=FormatAmiga(minor);
    Result:=Length(FDisc)>0;
   end;
 end;
end;

{-------------------------------------------------------------------------------
Extracts a file, filename contains complete path, directory separator is '.'
-------------------------------------------------------------------------------}
function TDiscImage.ExtractFile(filename: AnsiString; var buffer: TDIByteArray): Boolean;
var
 source        : Integer;
 entry,dir,
 frag,dest,
 fragptr,len,
 filelen       : Cardinal;
 fragments     : TFragmentArray;
begin
 //Does the file actually exist?
 Result:=FileExists(filename,fragptr);
 //Yes, so load it - there is nothing to stop a directory header being extracted
 //if passed in the filename parameter.
 if Result then
 begin
  //FileExists returns a pointer to the file
  entry:=fragptr mod $10000;  //Bottom 16 bits - entry reference
  dir  :=fragptr div $10000;  //Top 16 bits - directory reference
  //Make space to receive the file
  filelen:=FDisc[dir].Entries[entry].Length;
  SetLength(buffer,filelen);
  //Default values
  fragptr:=$0000;
  frag   :=0;
  //Get the starting position
  case FFormat shr 4 of
   //Acorn DFS
   $0: fragptr:=FDisc[dir].Entries[entry].Sector*$100; //Side is accounted for later
   //Acorn ADFS
   $1:
   begin
    if not FMap then //Old Map
     fragptr:=FDisc[dir].Entries[entry].Sector*$100;
    if FMap then //New Map
     //Get the fragment offsets of the file
     fragments:=NewDiscAddrToOffset(FDisc[dir].Entries[entry].Sector);
   end;
   //Commodore D61/D71/D81
   $2: fragptr:=ConvertDxxTS(FFormat AND $F,
                             FDisc[dir].Entries[entry].Track,
                             FDisc[dir].Entries[entry].Sector);
   //Commodore Amiga
   $4: fragptr:=Cardinal(FDisc[dir].Entries[entry].Sector);
  end;
  dest  :=0;      //Length pointer/Destination pointer
  len   :=filelen;//Amount of data to read in
  source:=fragptr;//Source pointer
  repeat
   //Fragmented filing systems, so need to work out source and length
   case FFormat shr 4 of
    $1:                           //Acorn ADFS New Map
    if FMap then
     if frag<Length(fragments) then
     begin
      source:=fragments[frag].Offset;           //Source of data
      len   :=fragments[frag].Length;           //Amount of data
     end;
    $2:                           //Commodore D64/D71/D81
    begin
     source:=fragptr+2;                        //Source of data
     len   :=254;                              //Amount of data
    end;
    $4:                           //Commodore Amiga
    begin
     source:=Integer(fragptr*secsize)+$18;     //Source of data
     len   :=Read32b(fragptr*secsize+$C,True);//Amount of data
    end;
   end;
   //Make sure we don't read too much
   if dest+len>filelen then
    len:=filelen-dest;
   //Read the data into the buffer
   ReadDiscData(source,len,FDisc[dir].Entries[entry].Side,buffer[dest]);
   //Move the size pointer on, by the amount read
   inc(dest,len);
   //Get the next block pointer
   case FFormat shr 4 of
    //Acorn ADFS - move onto next fragment
    $1: inc(frag);
    //Commodore d64/D71/D81 - find next block
    $2: fragptr:=ConvertDxxTS(FFormat AND $F,
                              ReadByte(fragptr),
                              ReadByte(fragptr+1));
    //Commodore Amiga - find next block
    $4: fragptr:=Read32b(fragptr*secsize+$10,True);
   end;
  until dest>=filelen; //Once we've reached the file length, we're done
 end;
 Result:=True;
end;

{-------------------------------------------------------------------------------
Extract a file into a memory stream
-------------------------------------------------------------------------------}
function TDiscImage.ExtractFileToStream(filename: AnsiString; F: TStream): Boolean;
var
 buffer: TDIByteArray;
begin
 //This just uses the previous function to get the file
 Result:=ExtractFile(filename,buffer);
 if Result then
 begin
  //Before we save it to the supplied stream
  F.Position:=0;
  F.Write(buffer[0],Length(buffer));
  F.Position:=0;
 end;
end;

{-------------------------------------------------------------------------------
Save a file into the disc image, from buffer
-------------------------------------------------------------------------------}
function TDiscImage.WriteFile(var file_details: TDirEntry; var buffer: TDIByteArray): Integer;
var
 m     : Byte;
 count : Integer;
begin
 //Start with a false result
 Result:=-1;
 //Get the length of data to be written
 count:=file_details.Length;
 //There are only two sides (max)
 file_details.Side:=file_details.Side mod 2;
 //Only write a file if there is actually any data to be written
 if count>0 then
 begin
  //Can only write a file that will fit on the disc
  if count<=free_space then
  begin
   m:=FFormat DIV $10; //Major format
   case m of
    0:Result:=WriteDFSFile(file_details,buffer);     //Write DFS
    1:Result:=WriteADFSFile(file_details,buffer);    //Write ADFS
    2:Result:=WriteCDRFile(file_details,buffer);     //Write Commodore 64/128
    3:Result:=WriteSpectrumFile(file_details,buffer);//Write Sinclair/Amstrad
    4:Result:=WriteAmigaFile(file_details,buffer);   //Write AmigaDOS
   end;
  end;
 end;
end;

{-------------------------------------------------------------------------------
Create a directory
-------------------------------------------------------------------------------}
function TDiscImage.CreateDirectory(var filename,parent,attributes: AnsiString): Integer;
var
 m     : Byte;
begin
 //Start with a false result
 Result:=-1;
 m:=FFormat DIV $10; //Major format
 case m of
  0: exit;//Can't create directories on DFS
  1:      //Create directory on ADFS
    Result:=CreateADFSDirectory(filename,parent,attributes);
  2: exit;//Can't create directories on Commodore
  3: exit;//Can't create directories on Sinclair/Amstrad
  4:      //Create directory on AmigaDOS
    Result:=CreateAmigaDirectory(filename,parent,attributes);
 end;
end;

{-------------------------------------------------------------------------------
Retitle a directory
-------------------------------------------------------------------------------}
function TDiscImage.RetitleDirectory(var filename,newtitle: AnsiString): Boolean;
var
 m     : Byte;
begin
 //Start with a false result
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0: exit;//DFS doesn't have directories
  1:      //Retitle ADFS directory
    Result:=RetitleADFSDirectory(filename,newtitle);
  2: exit;//Commodore doesn't have directories
  3: exit;//Sinclair/Amstrad doesn't have directories
  4:      //Retitle AmigaDOS directory
    Result:=RetitleAmigaDirectory(filename,newtitle);
 end;
end;

{-------------------------------------------------------------------------------
Save a file into the disc image, from stream
-------------------------------------------------------------------------------}
function TDiscImage.WriteFileFromStream(var file_details: TDirEntry;F: TStream): Integer;
var
 buffer: TDIByteArray;
begin
 //Copy the stream into a buffer
 SetLength(buffer,F.Size);
 F.Position:=0;
 F.Read(buffer[0],F.Size);
 //Then call the preceeding function to do the work
 Result:=WriteFile(file_details,buffer);
 //Return the pointer to the beginning of the stream
 F.Position:=0;
end;

{-------------------------------------------------------------------------------
Does a file exist?
-------------------------------------------------------------------------------}
function TDiscImage.FileExists(filename: AnsiString; var Ref: Cardinal): Boolean;
var
 Path   : array of AnsiString;
 i,j,l,
 ptr,
 level  : Integer;
 test,
 test2  : AnsiString;
begin
 Result:=False;
 //Not going to search if there is no tree to search in
 if Length(FDisc)>0 then
 begin
  SetLength(Path,0);
  j:=-1;
  ptr:=0;
  //Explode the pathname into an array, without the '.'
  if FFormat div $10<>$0 then //Not DFS
   while (Pos(dir_sep,filename)<>0) do
   begin
    SetLength(Path,Length(Path)+1);
    Path[Length(Path)-1]:=Copy(filename,0,Pos(dir_sep,filename)-1);
    filename:=Copy(filename,Pos(dir_sep,filename)+1,Length(filename));
   end;
  if FFormat div $10=$0 then //DFS
  begin
   SetLength(Path,2);
   Path[0]:=Copy(filename,0,Pos(root_name+dir_sep,filename));
   Path[1]:=Copy(filename,Pos(root_name+dir_sep,filename)
                         +Length(root_name)+Length(dir_sep),Length(filename));
  end;
  //If there is a path, then follow it
  if Length(Path)>0 then
  begin
   //filename gets truncated, so me be zero length at this point
   if (Length(filename)>0) and (FFormat div $10<>$0) then
   begin
    //Otherwise, we'll add it to the end of the Path
    SetLength(Path,Length(Path)+1);
    Path[Length(Path)-1]:=filename;
   end;
   //Position into the Path array (i.e. directory level)
   level:=0;
   //Counters/Pointers
   i:=0;
   j:=-1;
   ptr:=-1;
   test:=UpperCase(Path[level]);
   test2:=UpperCase(FDisc[i].Directory);
   if (FFormat=$01) and (test<>test2) then
    inc(i);
   //Using UpperCase makes it a case insensitive search
   if test=test2 then
    //Have we found the initial directory (usually '$')
    repeat
     //Let's move to the next directory level
     inc(level);
     //And search the entries
     j:=-1;
     repeat
      inc(j);
      test:='';
      if level<Length(Path) then
       test2:=UpperCase(Path[level])
      else
       test2:='not found';
      l:=j;
      //Just to make sure we don't search past the end of the arrays
      if (i>=0) and (i<Length(FDisc)) then
      begin
       if j<Length(FDisc[i].Entries) then
        test:=UpperCase(FDisc[i].Entries[j].Filename);
       l:=Length(FDisc[i].Entries)-1;
      end;
     until (test2=test) or (j>=l);
     //So, we found the entry
     if test2=test then
     begin
      //Make a note
      ptr:=i;
      //Is it a directory? Then move down to the next level
      if (i>=0) and (i<Length(FDisc)) then
       if j<Length(FDisc[i].Entries) then
       begin
        test2:=UpperCase(FDisc[i].Entries[j].Filename);
        i:=FDisc[i].Entries[j].DirRef;
        //Unless we are looking for a directory
        if level=Length(Path)-1 then
          if UpperCase(Path[level])=test2 then
           i:=-1;
       end;
     end
     else j:=-1;
    until (i=-1) or (j=-1); //End if it is not a directory, or is not found
  end;
   //Found, so return TRUE, with the references
  if j<>-1 then
  begin
   Result:=True;
   Ref:=ptr*$10000+j;
  end;
 end;
end;

{-------------------------------------------------------------------------------
Direct access to disc data
-------------------------------------------------------------------------------}
function TDiscImage.ReadDiscData(addr,count,side: Cardinal; var buffer): Boolean;
var
 i   : Cardinal;
 temp: TDIByteArray;
begin
 //Simply copy from source to destination
 //ReadByte will compensate if offset is out of range
 //All but DFS
 if FFormat shr 4<>0 then
 begin
  SetLength(temp,count);
  for i:=0 to count-1 do
   temp[i]:=ReadByte(addr+i);
 end;
 //DFS
 if FFormat shr 4=0 then
 begin
  SetLength(temp,count);
  for i:=0 to count-1 do
   temp[i]:=ReadByte(ConvertSector(addr+i,side));
 end;
 Move(temp[0],buffer,count);
 Result:=True;
end;

{-------------------------------------------------------------------------------
Direct access to disc data, into a stream
-------------------------------------------------------------------------------}
function TDiscImage.ReadDiscDataToStream(addr,count,side: Cardinal;F: TStream): Boolean;
var
 buffer: TDIByteArray;
begin
 //Set the length of the buffer
 SetLength(buffer,count);
 //Use the previous function to get the data
 Result:=ReadDiscData(addr,count,side,buffer[0]);
 if Result then
 begin
  //Then save it to the supplied stream
  F.Position:=0;
  F.Write(buffer[0],Length(buffer));
  F.Position:=0;
 end;
end;

{-------------------------------------------------------------------------------
Direct access writing to disc
-------------------------------------------------------------------------------}
function TDiscImage.WriteDiscData(addr,side: Cardinal;var buffer: TDIByteArray; count: Cardinal): Boolean;
var
 i   : Cardinal;
begin
 //Sometimes the image file is smaller than the actual disc size
 if Length(FData)<disc_size then SetLength(FData,disc_size);
 if FFormat DIV $10>0 then //not DFS
 begin
  //Ensure that the entire block will fit into the available space
  Result:=(addr+count)<=Cardinal(Length(Fdata));
  //Simply copy from source to destination
  if Result then
   for i:=0 to count-1 do
    WriteByte(buffer[i],addr+i);
 end
 else //DFS
 begin
  //Ensure that the entire block will fit into the available space
  Result:=ConvertSector(addr+count,side)<=Length(Fdata);
  //Simply copy from source to destination
  if Result then
   for i:=0 to count-1 do
    WriteByte(buffer[i],ConvertSector(addr+i,side));
 end;
end;

{-------------------------------------------------------------------------------
Direct access writing to disc from stream
-------------------------------------------------------------------------------}
function TDiscImage.WriteDiscDataFromStream(addr,side: Cardinal; F: TStream): Boolean;
var
 buffer: TDIByteArray;
begin
 //Set the length of the buffer
 SetLength(buffer,F.Size);
 //Copy the stream into the buffer
 F.Position:=0;
 F.Write(buffer[0],F.Size);
 //Use the previous function to write the data
 Result:=WriteDiscData(addr,side,buffer,Length(buffer));
 F.Position:=0;
end;

{-------------------------------------------------------------------------------
Searches for a file, and returns the result in a TSearchResults
-------------------------------------------------------------------------------}
function TDiscImage.FileSearch(search: TDirEntry): TSearchResults;
//Comparison functions...saves a lot of if...then statements
 function CompStr(S1,S2: AnsiString): Byte; //Compares Strings
 begin
  Result:=0;
  if (UpperCase(S1)=UpperCase(S2)) and (S1<>'') then Result:=1;
 end;
 function CompCar(S1,S2: Cardinal): Byte; //Compares Cardinals/Integers
 begin
  Result:=0;
  if (S1=S2) and (S1<>0) then Result:=1;
 end;
 function CompTSt(S1,S2: TDateTime): Byte; //Compares TDateTime
 begin
  Result:=0;
  if (S1=S2) and (S1<>0) then Result:=1;
 end;
//Function proper starts here
var
 dir,
 entry  : Integer;
 found,
 target : Byte;
begin
 //Reset the search results array to empty
 SetLength(Result,0);
 //Work out what the search target is
 target:=0;
 with search do
 begin
  if Parent       <>'' then inc(target);
  if Filename     <>'' then inc(target);
  if Attributes   <>'' then inc(target);
  if Filetype     <>'' then inc(target);
  if ShortFiletype<>'' then inc(target);
  if LoadAddr  <>$0000 then inc(target);
  if ExecAddr  <>$0000 then inc(target);
  if Length    <>$0000 then inc(target);
  if Side      <>$0000 then inc(target);
  if Track     <>$0000 then inc(target);
  if Sector    <>$0000 then inc(target);
  if DirRef    <>$0000 then inc(target);
  if TimeStamp <>0     then inc(target);
 end;
 //Only seach if there is something to search in
 if Length(FDisc)>0 then
  for dir:=0 to Length(FDisc)-1 do
   //Only search directories which have children
   if Length(FDisc[dir].Entries)>0 then
    for entry:=0 to Length(FDisc[dir].Entries)-1 do
    begin
     //Found counter
     found:=0;
     //Search parameters
     with FDisc[dir].Entries[entry] do
     begin
      inc(found,CompStr(search.Parent,       Parent));
      inc(found,CompStr(search.Filename,     Filename));
      inc(found,CompStr(search.Attributes,   Attributes));
      inc(found,CompStr(search.Filetype,     Filetype));
      inc(found,CompStr(search.ShortFiletype,ShortFiletype));
      inc(found,CompCar(search.LoadAddr,     LoadAddr));
      inc(found,CompCar(search.ExecAddr,     ExecAddr));
      inc(found,CompCar(search.Length,       Length));
      inc(found,CompCar(search.Side,         Side));
      inc(found,CompCar(search.Track,        Track));
      inc(found,CompCar(search.Sector,       Sector));
      inc(found,CompCar(search.DirRef,       DirRef));
      inc(found,CompTSt(search.TimeStamp,    TimeStamp));
     end;
     //Have we hit the target?
     //found is the number of matches found, and target is what we're aiming for
     if found=target then
     begin
      //Yes, so add this to the results
      SetLength(Result,Length(Result)+1);
      Result[Length(Result)-1]:=FDisc[dir].Entries[entry];
      //User will still need to call FileExists to get the dir and entry references
     end;
    end;
end;

{-------------------------------------------------------------------------------
Rename a file - oldfilename is full path, newfilename has no path
-------------------------------------------------------------------------------}
function TDiscImage.RenameFile(oldfilename: AnsiString;var newfilename: AnsiString): Boolean;
var
 m: Byte;
begin
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0:Result:=RenameDFSFile(oldfilename,newfilename);     //Rename DFS
  1:Result:=RenameADFSFile(oldfilename,newfilename);    //Rename ADFS
  2:Result:=RenameCDRFile(oldfilename,newfilename);     //Rename Commodore 64/128
  3:Result:=RenameSpectrumFile(oldfilename,newfilename);//Rename Sinclair/Amstrad
  4:Result:=RenameAmigaFile(oldfilename,newfilename);   //Rename AmigaDOS
 end;
end;

{-------------------------------------------------------------------------------
Deletes a file (given full pathname)
-------------------------------------------------------------------------------}
function TDiscImage.DeleteFile(filename: AnsiString): Boolean;
var
 m: Byte;
begin
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0:Result:=DeleteDFSFile(filename);     //Delete DFS
  1:Result:=DeleteADFSFile(filename);    //Delete ADFS
  2:Result:=DeleteCDRFile(filename);     //Delete Commodore 64/128
  3:Result:=DeleteSinclairFile(filename);//Delete Sinclair/Amstrad
  4:Result:=DeleteAmigaFile(filename);   //Delete AmigaDOS
 end;
end;

{-------------------------------------------------------------------------------
Moves a file from one directory to another
-------------------------------------------------------------------------------}
function TDiscImage.MoveFile(filename, directory: AnsiString): Integer;
begin
 //Moving and copying are the same, essentially
 Result:=CopyFile(filename,directory);
 //We just need to delete the original once copied
 if Result<>-1 then DeleteFile(filename);
end;

{-------------------------------------------------------------------------------
Copies a file from one directory to another
-------------------------------------------------------------------------------}
function TDiscImage.CopyFile(filename, directory: AnsiString): Integer;
var
 buffer      : TDIByteArray;
 ptr,
 entry,
 dir         : Cardinal;
 file_details: TDirEntry;
begin
 //Need to extract the filename from the full path...and ensure the file exists
 Result:=-1;
 if FileExists(filename,ptr) then
 begin
  //FileExists returns a pointer to the file
  entry:=ptr mod $10000;  //Bottom 16 bits - entry reference
  dir  :=ptr div $10000;  //Top 16 bits - directory reference
  //Make sure that we are not copying onto ourselves
  if Fdisc[dir].Entries[entry].Parent<>directory then
  begin
   //First, get the file into memory
   if ExtractFile(filename,buffer) then
   begin
    //Set up the filedetails
    file_details:=FDisc[dir].Entries[entry];
    file_details.Parent:=directory;
    //Then write it back to the image
    Result:=WriteFile(file_details,buffer);
   end;
  end;
 end;
end;

{-------------------------------------------------------------------------------
Set the attributes for a file
-------------------------------------------------------------------------------}
function TDiscImage.UpdateAttributes(filename,attributes: AnsiString):Boolean;
var
 m: Byte;
begin
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0:Result:=UpdateDFSFileAttributes(filename,attributes);     //Update DFS attributes
  1:Result:=UpdateADFSFileAttributes(filename,attributes);    //Update ADFS attributes
  2:Result:=UpdateCDRFileAttributes(filename,attributes);     //Update Commodore 64/128 attributes
  3:Result:=UpdateSinclairFileAttributes(filename,attributes);//Update Sinclair/Amstrad attributes
  4:Result:=UpdateAmigaFileAttributes(filename,attributes);   //Update AmigaDOS attributes
 end;
end;

{-------------------------------------------------------------------------------
Set the disc title
-------------------------------------------------------------------------------}
function TDiscImage.UpdateDiscTitle(title: AnsiString;side: Byte): Boolean;
var
 m: Byte;
begin
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0:Result:=UpdateDFSDiscTitle(title,side);//Title DFS Disc
  1:Result:=UpdateADFSDiscTitle(title);    //Title ADFS Disc
  2:Result:=UpdateCDRDiscTitle(title);     //Title Commodore 64/128 Disc
  3:Result:=UpdateSinclairDiscTitle(title);//Title Sinclair/Amstrad Disc
  4:Result:=UpdateAmigaDiscTitle(title);   //Title AmigaDOS Disc
 end;
end;

{-------------------------------------------------------------------------------
Set the boot option
-------------------------------------------------------------------------------}
function TDiscImage.UpdateBootOption(option,side: Byte): Boolean;
var
 m: Byte;
begin
 Result:=False;
 m:=FFormat DIV $10; //Major format
 case m of
  0:Result:=UpdateDFSBootOption(option,side);//Update DFS Boot
  1:Result:=UpdateADFSBootOption(option);    //Update ADFS Boot
  2: exit;//Update Commodore 64/128 Boot ++++++++++++++++++++++++++++++++++++++
  3: exit;//Update Sinclair/Amstrad Boot ++++++++++++++++++++++++++++++++++++++
  4: exit;//Update AmigaDOS Boot ++++++++++++++++++++++++++++++++++++++++++++++
 end;
end;

{$INCLUDE 'DiscImage_ADFS.pas'}
{$INCLUDE 'DiscImage_DFS.pas'}
{$INCLUDE 'DiscImage_C64.pas'}
{$INCLUDE 'DiscImage_Spectrum.pas'}
{$INCLUDE 'DiscImage_Amiga.pas'}

end.
