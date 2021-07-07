//++++++++++++++++++ Acorn FileStore +++++++++++++++++++++++++++++++++++++++++++

{-------------------------------------------------------------------------------
IDs an AFS disc
-------------------------------------------------------------------------------}
function TDiscImage.ID_AFS: Boolean;
 function IDAFSPass(chgint:Boolean): Boolean;
 var
  afspart1,
  afspart2,
  Lafsroot : Cardinal;
  index    : Integer;
  ok       : Boolean;
 begin
  ResetVariables;
  //Is there actually any data?
  if GetDataLength>0 then
  begin
   //Set default sector size and sectors per track
   secspertrack:= 16;
   secsize     :=256;
   //Is an AFS Level 2?
   if ReadString(0,-4)='AFS0' then
   begin
    //Need to set a format to fire off the interleave options
    FFormat:=diAcornFS<<4+1;
    if(FForceInter=0)and(chgint)then //Auto detect interleave
     Finterleave:=1; //Start with SEQ for AFS L2
    //The afs header address will be sectors 0 and 10
    afspart1:=$0*secsize;
    afspart2:=$A*secsize;
   end
   else //Not an AFS Level 2, so see if it is Level 3
   begin
    //Need to set a format to fire off the interleave options
    FFormat:=diAcornFS<<4+2;
    if(FForceInter=0)and(chgint)then //Auto detect interleave
     Finterleave:=3; //Start with MUX for AFS L3
    //Get the afs header address from the ADFS map
    afspart1:=Read24b($0F6)*secsize;
    afspart2:=Read24b($1F6)*secsize;
   end;
   //Have we got an ID header?
   if(ReadString(afspart1,-4)='AFS0')and(ReadString(afspart2,-4)='AFS0')then
   begin
    //Compare the two partition headers
    ok:=True;
    for index:=0 to $25 do
     if ReadByte(afspart1+index)<>ReadByte(afspart2+index)then ok:=False;
    //Both match? Do we have an ID string?
    if ok then
    begin
     //Level 2
     if FFormat=diAcornFS<<4+1 then
      //Confirm the root is where it says it is
      if ReadByte((Read24b(afspart1+$16)*secsize)+3)=$24 then afshead:=afspart1
      else FFormat:=diInvalidImg; //It isn't, so invalid image
     //Level 3
     if FFormat=diAcornFS<<4+2 then
     begin
      //Now we confirm we are looking at the root
      //Read where the header is pointing towards the root
      Lafsroot:=Read24b(afspart1+$1F)*$100;
      //Read the ID string
      if ReadString(Lafsroot,-6)='JesMap' then
       //Confirm it is the root
       if ReadByte((Read24b(Lafsroot+$0A)*secsize)+3)=$24 then // $24='$'
       begin
        afshead:=afspart1; //Make a note of the header location
        afshead2:=afspart2;//And the copy
       end
       else FFormat:=diInvalidImg //No root, invalid image
      else FFormat:=diInvalidImg; //No map ID, invalid image
     end;
    end else FFormat:=diInvalidImg; //Headers not matching, no format
   end else FFormat:=diInvalidImg; //No header ID, invalid image
  end;
  Result:=FFormat>>4=diAcornFS;
 end;
var
 start: Byte;
begin
 Result:=False;
 if FFormat=diInvalidImg then
 begin
  //Interleaving, depending on the option
  Finterleave:=FForceInter;
  if Finterleave=0 then Finterleave:=1; //Don't know the format, so go with SEQ
  //Do a first pass for ID
  Result:=IDAFSPass(True);
  //Are we set to autodetect interleaving, if no positive ID result?
  if(FForceInter=0)and(not Result)then //Auto
  begin
   start:=FInterleave;
   repeat
    //Next method
    dec(FInterleave);
    if FInterleave=0 then FInterleave:=4; //Wrap around
    Result:=IDAFSPass(False);
   until(Result)or(FInterleave=start); //Continue until a result or back at the start
  end;
 end;
end;

{-------------------------------------------------------------------------------
Reads an AFS partition
-------------------------------------------------------------------------------}
procedure TDiscImage.ReadAFSPartition;
var
 d,e,i    : Integer;
 allocmap : Cardinal;
 startdir : String;
 visited  : array of Cardinal;
begin
 visited:=nil;
 //Is this an ADFS disc with Acorn FileStore partition?
 if((FFormat>>4=diAcornADFS)and(FAFSPresent))
 or(FFormat>>4=diAcornFS)then
 begin
  if FFormat>>4=diAcornADFS then afshead:=Read24b($0F6)*secsize;
  //Confirm that there is a valid AFS partition here
  if ReadString(afshead,-4)='AFS0' then //Should be 'AFS0'
  begin
   //Update the progress indicator
   UpdateProgress('Reading Acorn FS partition');
   //Size of the disc
   if FFormat=diAcornFS<<4+1 then //Level 2
    disc_size[0]:=Read16b(afshead+$14)*2*secsize; //Only gives number of sectors for 1 side
   if FFormat=diAcornFS<<4+2 then //Level 3
    disc_size[0]:=Read16b(afshead+$16)*secsize;
   i:=0;
   if FFormat>>4=diAcornADFS then //Level 3/ADFS Hybrid
   begin
    SetLength(disc_size,2);
    SetLength(free_space,2);
    SetLength(disc_name,2);
    disc_size[1]:=(Read16b(afshead+$16)*secsize)-disc_size[0];
    i:=1;
   end;
   //Disc title
   disc_name[i]:=ReadString(afshead+4,-16);
   RemoveSpaces(disc_name[i]); //Minus trailing spaces
   //Where is the AFS root?
   if FFormat=diAcornFS<<4+1 then
    allocmap:=Read24b(afshead+$16)*secsize //Level 2
   else
    allocmap:=Read24b(afshead+$1F)*secsize;//Level 3
   //Is the ADFS root broken with no entries (i.e. valid?)
   if Length(FDisc)>0 then //This will also be zero if this is an AFS image
    if(FDisc[0].Broken)and(Length(FDisc[0].Entries)=0)then
     SetLength(FDisc,0); //Yes, so overwrite it
   //Add a new entry
   d:=Length(FDisc);
   SetLength(FDisc,d+1);
   //Start the chain by reading the root
   if FFormat>>4=diAcornADFS then startdir:=':AFS$' else startdir:='$';
   FDisc[d]:=ReadAFSDirectory(startdir,allocmap);
   //Add the root as a visited directory
   SetLength(visited,1);
   visited[0]:=allocmap div secsize;
   //Now go through the root's entries and read them in
   repeat
    if Length(FDisc[d].Entries)>0 then
     for e:=0 to Length(FDisc[d].Entries)-1 do
     begin
      //Make sure we haven't seen this before. If a directory references a higher
      //directory we will end up in an infinite loop.
      if Length(visited)>0 then
       for i:=0 to Length(visited)-1 do
        if visited[i]=FDisc[d].Entries[e].Sector then
         FDisc[d].Entries[e].Filename:='';//Blank off the filename so we can remove it later
      if FDisc[d].Entries[e].Filename<>'' then //Needs to have an actual name
       //If it is a directory, read that in
       if Pos('D',FDisc[d].Entries[e].Attributes)>0 then
       begin
        //Making room for it
        SetLength(FDisc,Length(FDisc)+1);
        //And now read it in
        FDisc[Length(FDisc)-1]:=ReadAFSDirectory(FDisc[d].Entries[e].Parent
                                                +dir_sep
                                                +FDisc[d].Entries[e].Filename,
                                                FDisc[d].Entries[e].Sector*secsize);
        //Remember it
        SetLength(visited,Length(visited)+1);
        visited[Length(visited)-1]:=FDisc[d].Entries[e].Sector;
        //Reference to it
        FDisc[d].Entries[e].DirRef:=Length(FDisc)-1;
       end;
     end;
    inc(d);
   until d=Length(FDisc);
   //Update the progress indicator
   UpdateProgress('Removing blank entries');
   //Remove any blank entries or parent directory references
   if Length(FDisc)>0 then
   begin
    //Directory counter
    d:=0;
    //Iterate through all directories
    while d<Length(FDisc) do
    begin
     //Are there any entries?
     if Length(FDisc[d].Entries)>0 then
     begin
      //Entry counter
      e:=0;
      //Iterate through all entries
      while e<Length(FDisc[d].Entries) do
      begin
       //Do we have a blank filename?
       if FDisc[d].Entries[e].Filename='' then
       begin
        //If not the last entry
        if e<Length(FDisc[d].Entries)-1 then
        //Move the entries above it down by one
         for i:=e+1 to Length(FDisc[d].Entries)-1 do
          FDisc[d].Entries[i-1]:=FDisc[d].Entries[i];
        //Remove the final entry
        SetLength(FDisc[d].Entries,Length(FDisc[d].Entries)-1);
       end;
       //Next entry (which now could take us over the length)
       inc(e);
      end;
     end;
     //Next directory
     inc(d);
    end;
   end;
   //Read in the free space map
   ReadAFSFSM;
  end
  else FAFSPresent:=False; //No valid partition
 end;
end;

{-------------------------------------------------------------------------------
Reads an AFS directory
-------------------------------------------------------------------------------}
function TDiscImage.ReadAFSDirectory(dirname:String;addr: Cardinal):TDir;
var
 numentries,
 index,
 day,
 month,
 year       : Integer;
 side,
 entry,
 objaddr,
 segaddr    : Cardinal;
 attr       : String;
 access     : Byte;
 buffer     : TDIByteArray;
begin
 Result.Directory:='';
 buffer:=nil;
 //Reset the directory settings to a default value
 ResetDir(Result);
 //Update the progress indicator
 UpdateProgress('Reading '+dirname);
 //Read, and assemble, the directory into a temporary buffer, if valid
 buffer:=ReadAFSObject(addr);
 //Have we got any data to look at?
 if Length(buffer)>0 then
 begin
  //And set the partition flag to true
  Result.AFSPartition:=True;
  //ADFS hybrid?
  if FFormat>>4=diAcornADFS then side:=1 else side:=0;
  Result.Partition:=side;
  //Directory title
  Result.Directory:=ReadString($03,-10,buffer);
  RemoveSpaces(Result.Directory);
  if Result.Directory='$' then
  begin
   Result.Directory:=dirname; //Change the name, in case we already have a '$'
   Fafsroot:=addr div secsize; //Make a note of where the root is
   afsroot_size:=GetAFSObjLength(addr); //And a note of the root size
  end;
  //Number of entries in the directory
  numentries:=ReadByte($0F,buffer);
  SetLength(Result.Entries,numentries);
  //Pointer to first entry
  entry:=Read16b($00,buffer);
  //Read all the entries in
  if(numentries>0)and(entry>0)then
   for index:=0 to numentries-1 do
   begin
    //Reset all other entries
    Result.Entries[index].FileType:='';
    Result.Entries[index].ShortFileType:='';
    Result.Entries[index].Parent:=dirname;
    Result.Entries[index].Side:=side;
    //Filename
    Result.Entries[index].Filename:=ReadString(entry+$02,-10,buffer);
    RemoveSpaces(Result.Entries[index].Filename);
    //Load address
    Result.Entries[index].LoadAddr:=Read32b(entry+$0C,buffer);
    //Execution address
    Result.Entries[index].ExecAddr:=Read32b(entry+$10,buffer);
    //Attributes
    attr:='';
    access:=ReadByte(entry+$14,buffer);
    if access AND $20=$20 then attr:=attr+'D';
    if access AND $10=$10 then attr:=attr+'L';
    if access AND $08=$08 then attr:=attr+'W';
    if access AND $04=$04 then attr:=attr+'R';
    if access AND $02=$02 then attr:=attr+'w';
    if access AND $01=$01 then attr:=attr+'r';
    Result.Entries[index].Attributes:=attr;
    //Modification Date
    segaddr:=Read16b(entry+$15,buffer);
    day:=segaddr AND$1F;//Day;
    month:=(segaddr AND$F00)>>8; //Month
    year:=((segaddr AND$F000)>>12)+((segaddr AND$E0)>>1)+1981; //Year
    if(day>0)and(day<32)and(month>0)and(month<13)then
     Result.Entries[index].TimeStamp:=EncodeDate(year,month,day)
    else
     Result.Entries[index].TimeStamp:=0;
    //Location  of the object
    objaddr:=Read24b(entry+$17,buffer)*secsize;
    if(ReadString(objaddr,-6)='JesMap')or(FFormat=diAcornFS<<4+1)then
    begin
     //Location of the data
     Result.Entries[index].Sector:=objaddr div secsize;
     //Length
     Result.Entries[index].Length:=GetAFSObjLength(objaddr);
    end
    else
    begin //Invalid block, so blank these parameters off
     Result.Entries[index].Sector:=0;
     Result.Entries[index].Length:=0;
    end;
    //Directory Reference
    Result.Entries[index].DirRef:=-1;
    //Next entry
    entry:=Read16b(entry+$00,buffer);
   end;
 end;
end;

{-------------------------------------------------------------------------------
Extracts a file, filename contains complete path
-------------------------------------------------------------------------------}
function TDiscImage.ExtractAFSFile(filename: String;
                                             var buffer: TDIByteArray): Boolean;
var
 dir,
 entry : Cardinal;
begin
 Result:=False;
 if FileExists(filename,dir,entry) then //Does the file actually exist?
 begin
  //Just use the method for reading in objects
  buffer:=ReadAFSObject(FDisc[dir].Entries[entry].Sector*secsize);
  //And return a positive result
  Result:=True;
 end;
end;

{-------------------------------------------------------------------------------
Read and assemble an object's data
-------------------------------------------------------------------------------}
function TDiscImage.ReadAFSObject(offset: Cardinal): TDIByteArray;
var
 ptr,
 addr,
 len,
 bufptr,
 almap : Cardinal;
 index : Integer;
begin
 Result:=nil;
 //Make sure it is a valid allocation map for Level 3
 if(ReadString(offset,-6)='JesMap')
 and((FFormat=diAcornFS<<4+2)or(FFormat>>4=diAcornADFS))then
 begin
  //Start of the list
  ptr:=$0A;
  //Read the first entry and length
  addr:=$FF;
  while(addr<>0)and(ptr<$FA)do
  begin
   addr:=Read24b(offset+ptr)*secsize;
   len:=Read16b(offset+ptr+3)*secsize;
   bufptr:=Length(Result);
   //Copy into the buffer
   SetLength(Result,Length(Result)+len);
   for index:=0 to len-1 do
    Result[bufptr+index]:=ReadByte(addr+index);
   //Move onto the next entry
   inc(ptr,5);
  end;
  //Truncate to the total length
  len:=ReadByte(offset+$08);
  if(addr=0)and(len>0)then
  begin
   len:=$100-len;
   SetLength(Result,Length(Result)-len);
  end;
 end;
 //We are looking at a Level 2 map, with no ID string
 if(FFormat=diAcornFS<<4+1)and(offset<>0)then
 begin
  offset:=offset div secsize;
  //Get the address of the current allocation map
  almap:=GetAllocationMap;
  //Find our entry and read it in
  repeat
   addr:=Read16b(almap+(offset*2)+5);
   len:=secsize; //Length of data to read in
   if (addr AND $4000)=$4000 then
   begin
    len:=addr AND $FF;//Last sector, so bytes used
    if len=0 then len:=secsize; //if zero, then it must be a full sector
   end;
   if (addr AND $1000)=$1000 then len:=0; //This entry is empty
   if len>0 then
   begin
    //Copy the data into the buffer
    bufptr:=Length(Result);
    SetLength(Result,bufptr+len);
    for index:=0 to len-1 do
     Result[bufptr+index]:=ReadByte(offset*secsize+index);
   end;
   if (addr AND $4000)<>$4000 then offset:=addr AND $FFF; //This is the next sector in the chain
  until (addr AND $4000)=$4000; //Continue until everything is read in
 end;
end;

{-------------------------------------------------------------------------------
Read the length of an object
-------------------------------------------------------------------------------}
function TDiscImage.GetAFSObjLength(offset: Cardinal): Cardinal;
var
 almap,
 addr,
 len,
 ptr,
 segaddr: Cardinal;
 lenLSB : Byte;
begin
 Result:=0;
 //Level 2
 if(FFormat=diAcornFS<<4+1)and(offset<>0)then
 begin
  offset:=offset*secsize;
  //Get the address of the current allocation map
  almap:=GetAllocationMap;
  //Find our entry and read it in
  repeat
   addr:=Read16b(almap+(offset*2)+5);
   //Length of data in this sector
   len:=secsize;
   if (addr AND $4000)=$4000 then
   begin
    //Last sector, so bytes used
    len:=addr AND $FF;
    //if zero, then it must be a full sector
    if len=0 then len:=secsize;
   end;
   if (addr AND $1000)=$1000 then len:=0; //This entry is empty
   //Add to the total
   inc(Result,len);
   if (addr AND $4000)<>$4000 then offset:=addr AND $FFF; //This is the next sector in the chain
  until (addr AND $4000)=$4000; //Continue until everything is read in
 end;
 //Level 3
 if(ReadString(offset,-6)='JesMap')
 and((FFormat=diAcornFS<<4+2)or(FFormat>>4=diAcornADFS))then
 begin
  lenLSB:=ReadByte(offset+$08); //LSB of the length
  ptr:=$0A;
  segaddr:=$FF;
  while(ptr<$FA)and(segaddr<>$00)do
  begin
   //Read the segment address
   segaddr:=Read24b(offset+ptr);
   //Read the length of this segment and add to the total
   inc(Result,Read16b(offset+ptr+3));
   //Next segment
   inc(ptr,5);
  end;
  //Total length read, but may be over
  if lenLSB>0 then
   Result:=(Result-1)*secsize+lenLSB
  else
   Result:=Result*secsize;
 end;
end;

{-------------------------------------------------------------------------------
Gets the Level 2 allocation map address
-------------------------------------------------------------------------------}
function TDiscImage.GetAllocationMap: Cardinal;
begin
 Result:=0; //Default
 if FFormat=diAcornFS<<4+1 then //Only Level 2
  if ReadByte(Read24b(afshead+$1B)*secsize)>ReadByte(Read24b(afshead+$1E)*secsize)then
   Result:=Read24b(afshead+$1B)*secsize else Result:=Read24b(afshead+$1E)*secsize;
end;

{-------------------------------------------------------------------------------
Read the free space map
-------------------------------------------------------------------------------}
procedure TDiscImage.ReadAFSFSM;
var
 nument,
 allocmap,
 index,
 entry,
 szofbmp,
 bmploc,
 afsstart,
 trackstrt    : Cardinal;
 Lsecspertrack: Word;
 Ldiscsize    : Int64;
 status,
 part         : Byte;
begin
 //Update the progress indicator
 UpdateProgress('Reading the free space map');
 if FFormat>>4=diAcornFS then
 begin
  //Initialise the variables
  free_space[0]:=0;
  SetLength(free_space_map,0);
 end;
 //Level 2
 if FFormat=diAcornFS<<4+1 then
 begin
  //Get the allocation map address
  allocmap:=GetAllocationMap;
  //From this, the number of entries
  nument:=disc_size[0]div secsize;//Read16b(allocmap+1);
  //Set up the FSM array
  SetLength(free_space_map,1); //1 side
  SetLength(free_space_map[0],(disc_size[0]div secsize)div secspertrack); //Tracks
  for entry:=0 to Length(free_space_map[0])-1 do //Sectors per track
  begin
   SetLength(free_space_map[0,entry],secspertrack);
   for index:=0 to secspertrack-1 do free_space_map[0,entry,index]:=$00;
  end;
  //Now populate the FSM
  for entry:=0 to nument-1 do
  begin
   //Read the status of this sector
   status:=ReadByte(allocmap+6+(entry*2));
   if (status AND $80)=$80 then //If it has been written then mark as used
   begin
    free_space_map[0,entry div secspertrack,entry mod secspertrack]:=$FF;
    inc(free_space[0],secsize);
   end;
  end;
  //Calculate the free space
  free_space[0]:=disc_size[0]-free_space[0];
 end;
 //Level 3 and ADFS/AFS Hybrid
 if FFormat<>diAcornFS<<4+1 then
 begin
  Lsecspertrack:=Read16b(afshead+$1A);
  //Level 3
  if FFormat=diAcornFS<<4+2 then
  begin
   SetLength(free_space_map,1); //One partition, so one FSM
   part:=0;                     //Point to this FSM
   Ldiscsize:=disc_size[0]-$200;//Look at the entire image
   afsstart:=$200;              //But not below here, which is ADFS header
   free_space[0]:=0;            //Free Space
  end
  else
  begin //Hybrids - AFS will take up the second 'side'
   SetLength(free_space_map,2); //Two partitions, so two FSMs
   part:=1;                     //Point to this FSM
   Ldiscsize:=disc_size[1];     //Only look at the AFS part of the image
   afsstart:=disc_size[1];      //And not below here, which is the ADFS partition
   free_space[1]:=0;            //Free space
  end;
  //Set up the array
  SetLength(free_space_map[part],
            Ceil((Ldiscsize div secsize)/Lsecspertrack)); //Tracks
  for entry:=0 to Length(free_space_map[part])-1 do //Sectors per track
  begin
   SetLength(free_space_map[part,entry],Lsecspertrack);
   for index:=0 to Lsecspertrack-1 do free_space_map[part,entry,index]:=$FD;
  end;
  //Read the size of the bitmap
  szofbmp:=ReadByte(afshead+$1C)*secsize;
  //Is it big enough to hold the entire disc?
  if szofbmp>=(((afsstart+Ldiscsize) div secsize)div 8)+1 then //Yes
  begin
   //Location of the bitmap (just before the root)
   bmploc:=(afsroot*secsize)-szofbmp;
   //Go through the bitmap, sector by sector
   for index:=0 to (Ldiscsize div secsize)-1 do
    //Is the bit set, then it is free
    if IsBitSet(ReadByte(bmploc+(index div 8)),index mod 8) then
     free_space_map[part,index div Lsecspertrack,index mod Lsecspertrack]:=$00
    else //Otherwise mark as used
    begin
     if(index*secsize=afshead)or(index*secsize=afshead2)
     or((index*secsize>=afsroot)and(index*secsize<=afsroot+afsroot_size))
     or((index*secsize>=bmploc)and(index*secsize<=bmploc+szofbmp))then //System?
      free_space_map[part,index div Lsecspertrack,index mod Lsecspertrack]:=$FE
     else //Or data?
      free_space_map[part,index div Lsecspertrack,index mod Lsecspertrack]:=$FF;
     //Add to the free space count
     inc(free_space[part],secsize);
    end;
  end
  else //Not big enough for entire disc, so will be on every track
  begin
   //Get the sector offset of each track
   trackstrt:=Lsecspertrack*secsize;
   //Our counter - first track after the ADFS part
   bmploc:=(afsstart div trackstrt)*trackstrt;
   if bmploc<afsstart then bmploc:=trackstrt;
   while bmploc<afsstart+Ldiscsize do //Do the entire image, track by track
   begin
    //Every sector per track
    for index:=0 to Lsecspertrack-1 do
     //Is the bit set?
     if IsBitSet(ReadByte(bmploc+(index div 8)),index mod 8) then
      free_space_map[part,(bmploc-afsstart)div trackstrt,index]:=$00 //Mark as free
     else //Otherwise it is used
     begin
      if(bmploc+index*secsize=afshead)or(bmploc+index*secsize=afshead2)
      or((bmploc+index*secsize>=afsroot)and(bmploc+index*secsize<=afsroot+afsroot_size))
      or(index*secsize<=szofbmp)then //But is it system
       free_space_map[part,(bmploc-afsstart)div trackstrt,index]:=$FE
      else //or just data?
       free_space_map[part,(bmploc-afsstart)div trackstrt,index]:=$FF;
      //Add to the free space count
      inc(free_space[part],secsize);
     end;
    //Move on to the next track
    inc(bmploc,trackstrt);
   end;
  end;
  //Invert the free space from 'used' to 'free'
  free_space[part]:=Ldiscsize-free_space[part];
 end;
end;

{-------------------------------------------------------------------------------
Create a blank AFS image
-------------------------------------------------------------------------------}
function TDiscImage.FormatAFS(harddrivesize: Cardinal;afslevel: Byte): Boolean;
var
 index     : Integer;
 c,y,m,d   : Byte;
 cdate,
 freesecs,
 firstfree : Word;
 mapsize,
 mapsizeal,
 allocmap1,
 allocmap2 : Cardinal;
const
 deftitle = 'DiscImageManager';
 afsID    = 'AFS0';
 objID    = 'JesMap';
 cycle    = 42; //Random...42 - the answer to life, the universe and everything
begin
 Result:=False;
 if(afslevel=2)or(afslevel=3)then
 begin
  //Blank everything
  ResetVariables;
  SetDataLength(0);
  //Set the format
  FFormat:=diAcornFS<<4+(afslevel-1);
  //Set the filename
  imagefilename:='Untitled.'+FormatExt;
  //Setup the data area
  disc_size[0]:=harddrivesize;
  SetDataLength(disc_size[0]);
  //Fill with zeros
  for index:=0 to disc_size[0]-1 do WriteByte(0,index);
  //Set the boot option
  SetLength(bootoption,1);
  bootoption[0]:=0;
  SetLength(free_space_map,1); //Free Space Map
  //Default sizes
  secsize:=256;
  secspertrack:=16;
  //Interleave option
  if FForceInter=0 then
   if afslevel=3 then Finterleave:=3 //MUX - Default for AFS L3
   else Finterleave:=1 //SEQ - default for AFS L2
  else Finterleave:=FForceInter;
  //Level 2
  if afslevel=2 then
  begin
   //Where the header is located
   afshead:=$000;
   afshead2:=afshead+$A00;
   //Write the AFS headers
   //ID at $00
   for index:=0 to 3 do WriteByte(Ord(afsID[index+1]),afshead+index);
   //Title at $04
   for index:=0 to 15 do
   begin
    c:=$20;//Padded with spaces
    if index<Length(deftitle) then c:=Ord(deftitle[index+1]);
    WriteByte(c,afshead+$04+index);
   end;
   //Sectors for one side at $14
   Write16b((harddrivesize>>8)div 2,afshead+$14);
   //Root SIN at $16
   Fafsroot:=afshead+$200;
   afsroot_size:=$200;//Root is 2 sectors long
   Write24b(Fafsroot>>8,afshead+$16);
   //Creation Date at $19
   y:=StrToIntDef(FormatDateTime('yyyy',Now),1981)-1981;//Year
   m:=StrToIntDef(FormatDateTime('m',Now),1);           //Month
   d:=StrToIntDef(FormatDateTime('d',Now),1);           //Date
   cdate:=((y AND$F)<<12)OR((y AND$F0)<<1)OR(d AND$1F)OR((m AND$F)<<8);
   Write16b(cdate,afshead+$19);
   //Map A location at $1B
   allocmap1:=afshead2+$100;
   Write24b(allocmap1>>8,afshead+$1B);
   //Map B location at $1E
   mapsize:=5+((harddrivesize>>8)*2);
   //Round up to the next sector boundary
   mapsizeal:=(mapsize>>8)<<8+Ceil((mapsize mod $100)/$100)<<8;
   allocmap2:=allocmap1+mapsizeal;
   Write24b(allocmap2>>8,afshead+$1E);
   //Size of map at $21
   Write24b(mapsize,afshead+$21);
   //Rest of the sector filled with $00000080
   index:=$24;
   while index<$FF do
   begin
    Write32b($00000080,afshead+index);
    inc(index,4);
   end;
   //Copy the primary header to the copy
   for index:=0 to $FF do WriteByte(ReadByte(afshead+index),afshead2+index);
   //Write the directory object for $
   //Pointer to first entry at $00
   Write16b($0000,Fafsroot+$00);
   //Cycle number at $02
   WriteByte(cycle,Fafsroot+$02);
   //Directory name at $03
   WriteByte(Ord('$'),Fafsroot+$03);
   for index:=1 to 9 do WriteByte($20,Fafsroot+$03+index);
   //Pointer to first free entry at $0D
   Write16b($11,Fafsroot+$0D);
   //Number of entries in directory at $0F
   WriteByte(0,Fafsroot+$0F);
   //Copy of cycle number at end of root
   WriteByte(cycle,Fafsroot+afsroot_size-1);
   //Write the image allocation map
   for index:=0 to (harddrivesize>>8)-1 do   //Blank entries just reference the
    Write16b(index+1,allocmap1+5+(index*2)); //next sector.
   //AFS Headers
   WriteBits(1,allocmap1+6,7,1); //sector 0 mark as written
   WriteBits(1,allocmap1+26,7,1);//sector 10 mark as written
   WriteBits(1,allocmap1+6,6,1); //sector 0 end of chain
   WriteBits(1,allocmap1+26,6,1);//sector 10 end of chain
   WriteBits(1,allocmap1+6,5,1); //sector 0 start of chain
   WriteBits(1,allocmap1+26,5,1);//sector 10 start of chain
   WriteByte(0,allocmap1+5);     //No next sector
   WriteByte(0,allocmap1+25);    //No next sector
   //Sector 1 and sector 801 (blank sectors for DFS) are not used
   WriteBits(1,allocmap1+8,7,1);   //sector 1 mark as written
   WriteBits(1,allocmap1+1608,7,1);//sector 801 mark as written
   WriteBits(1,allocmap1+8,6,1);   //sector 1 end of chain
   WriteBits(1,allocmap1+1608,6,1);//sector 801 end of chain
   WriteBits(1,allocmap1+8,5,1);   //sector 1 start of chain
   WriteBits(1,allocmap1+1608,5,1);//sector 801 start of chain
   WriteByte(0,allocmap1+7);       //No next sector
   WriteByte(0,allocmap1+1607);    //No next sector
   //Root
   WriteBits(1,allocmap1+6+Fafsroot>>7,5,1);//Start
   WriteBits(1,allocmap1+6+Fafsroot>>7,7,1);//Has been written
   WriteBits(1,allocmap1+6+(Fafsroot+afsroot_size)>>7-2,6,1);//End
   WriteBits(1,allocmap1+6+(Fafsroot+afsroot_size)>>7-2,7,1);//Has been written
   WriteByte(0,allocmap1+5+(Fafsroot+afsroot_size)>>7-2);//Zero length LSB
   if afsroot_size>>8>2 then
    for index:=1 to (afsroot_size>>8)-1 do
     WriteBits(1,allocmap1+6+((Fafsroot>>8)+index)*2,7,1);
   //Allocation Maps
   for index:=0 to mapsize>>8 do
   begin
    WriteBits(1,allocmap1+6+((allocmap1>>8)+index)*2,7,1);
    WriteBits(1,allocmap1+6+((allocmap2>>8)+index)*2,7,1);
   end;
   dec(mapsizeal,$100);//Otherwise we will encroach onto the second map
   WriteBits(1,allocmap1+6+allocmap1>>7,5,1); //Start
   WriteBits(1,allocmap1+6+(allocmap1+mapsizeal)>>7,6,1); //End
   WriteByte(0,allocmap1+5+(allocmap1+mapsizeal)>>7);
   WriteBits(1,allocmap1+6+allocmap2>>7,5,1); //Start
   WriteBits(1,allocmap1+6+(allocmap2+mapsizeal)>>7,6,1); //End
   WriteByte(0,allocmap1+5+(allocmap2+mapsizeal)>>7);
   //Work out and set the number of free sectors and pointer to first free
   freesecs:=0;      //Counter for number of free sectors
   firstfree:=$FFFF; //Dummy start
   index:=5;         //Start at the beginning
   while index<mapsize do
   begin
    if ReadBits(allocmap1+index+1,7,1)=0 then //Bit 7 is not set, so is unwritten
    begin
     inc(freesecs); //Count it as a free sector
     if firstfree=$FFFF then     //Is it the first?
      firstfree:=(index-5)div 2; //then record it
    end;
    inc(index,2);//Next sector
   end;
   Write16b(freesecs,allocmap1+1); //Write the free sector count to the map
   Write16b(firstfree,allocmap1+3);//Write the first free sector to the map
   //Now re-align the unwritten sector pointers so they jump over the written ones
   index:=mapsize-2;//Start at the end
   firstfree:=(index-5)div 2;//And take note of the next sector
   while index>5 do //Continue until we reach the start
   begin
    dec(index,2); //Entries are 2 bytes long
    if ReadBits(allocmap1+index+1,7,1)=0 then //If unwritten
    begin
     Write16b(firstfree,allocmap1+index);     //Write the last known free
     firstfree:=(index-5)div 2;               //And update to point to this one
    end;
   end;
   //Mark end of map
   Write16b(0,allocmap1+mapsize-2);
   WriteBits(1,allocmap1+mapsize-1,6,1);
   //Copy the primary allocation map to the copy
   for index:=0 to mapsize-1 do
    WriteByte(ReadByte(allocmap1+index),allocmap2+index);
   //Update the current map indicators
   WriteByte($02,allocmap1);
   WriteByte($01,allocmap2);
   //Mark as a success
   Result:=True;
  end;
  //Level 3
  if afslevel=3 then
  begin
   //Where the header is located
   afshead:=$200;
   afshead2:=afshead+$100;
   //Install a basic ADFS map
   Write24b($20,$000);//FreeStart
   Write24b(afshead>>8,$0F6);//AFS Header copy 1
   Write24b($20,$0FC);//Disc size
   WriteByte(ByteCheckSum($0000,$100),$0FF);//Checksum sector 0
   Write24b($00,$100);//FreeEnd
   Write24b(afshead2>>8,$1F6);//AFS Header copy 2
   WriteByte(ByteCheckSum($0100,$100),$1FF);//Checksum sector 1
   //Write the AFS headers
   //ID at $00
   for index:=0 to 3 do WriteByte(Ord(afsID[index+1]),afshead+index);
   //Title at $04
   for index:=0 to 15 do
   begin
    c:=$20;//Padded with spaces
    if index<Length(deftitle) then c:=Ord(deftitle[index+1]);
    WriteByte(c,afshead+$04+index);
   end;
   //Tracks at $14
   Write16b((harddrivesize>>8)div secspertrack,afshead+$14);
   //Disc size (number of sectors) at $16
   Write24b(harddrivesize>>8,afshead+$16);
   //Partitions at $19
   WriteByte(1,afshead+$19);
   //Sectors per track at $1A
   Write16b(secspertrack,afshead+$1A);
   //Size of bitmap at $1C
   mapsize:=Ceil(((harddrivesize>>8)/8)/secsize);
   WriteByte(mapsize,afshead+$1C);
   mapsize:=mapsize<<8;
   //Next drive at $1D
   WriteByte($01,afshead+$1D);
   // $00 at $1E
   WriteByte($00,afshead+$1E);
   //Root SIN at $1F
   Fafsroot:=afshead2+$100+mapsize;
   Write24b(Fafsroot>>8,afshead+$1F);
   //Creation Date at $22
   y:=StrToIntDef(FormatDateTime('yyyy',Now),1981)-1981;//Year
   m:=StrToIntDef(FormatDateTime('m',Now),1);           //Month
   d:=StrToIntDef(FormatDateTime('d',Now),1);           //Date
   cdate:=((y AND$F)<<12)OR((y AND$F0)<<1)OR(d AND$1F)OR((m AND$F)<<8);
   Write16b(cdate,afshead+$22);
   //First free cylinder at $24
   Write16b(1,afshead+$24); //Not sure why it is always 1
   // $04 at $26
   WriteByte($04,afshead+$26);
   //Copy the primary header to the copy
   for index:=0 to $FF do WriteByte(ReadByte(afshead+index),afshead2+index);
   //Now to write the root
   //ID at $00
   for index:=0 to 5 do WriteByte(Ord(objID[index+1]),Fafsroot+index);
   //Map chain sequence number at $06
   WriteByte(cycle,Fafsroot+$06);
   // $00 at $07
   WriteByte($00,Fafsroot+$07);
   //LSB of object length at $08
   WriteByte($00,Fafsroot+$08);
   // $00 at $09
   WriteByte($00,Fafsroot+$09);
   //First group of allocated sectors at $0A
   //Sector at $0A (3 bytes)
   Write24b((Fafsroot>>8)+1,Fafsroot+$0A);
   //Length at $0D (2 bytes)
   afsroot_size:=$200;//Root is 2 sectors long
   Write16b(afsroot_size>>8,Fafsroot+$0D);
   //Copy of map chain sequence number at $FF
   WriteByte(cycle,Fafsroot+$FF);
   //Write the directory object for $
   //Pointer to first entry at $100
   Write16b($0000,Fafsroot+$100);
   //Cycle number at $102
   WriteByte(cycle,Fafsroot+$102);
   //Directory name at $103
   WriteByte(Ord('$'),Fafsroot+$103);
   for index:=1 to 9 do WriteByte($20,Fafsroot+$103+index);
   //Pointer to first free entry at $10D
   Write16b($2B,Fafsroot+$10D);
   //Number of entries in directory at $10F
   WriteByte(0,Fafsroot+$10F);
   //First entry at $111 (pointer is $FFFF to indicate parent)
   Write16b($FFFF,Fafsroot+$111);
   //Copy of cycle number at end of root
   WriteByte(cycle,Fafsroot+afsroot_size-1);
   //Write the image bitmap
   for index:=0 to mapsize-1 do WriteByte($FF,afshead2+$100+index);
   for index:=0 to (Fafsroot>>8)+2 do
    WriteBits(0,afshead2+$100+(index div 8),index mod 8,1);
   //Mark as a success
   Result:=True;
  end;
  //Finalise the the variables by reading in the partition
  if Result then ReadAFSPartition;
 end;
end;

{-------------------------------------------------------------------------------
Create a blank AFS password file (this is a public method)
-------------------------------------------------------------------------------}
function TDiscImage.CreateAFSPassword: Boolean;
begin
 Result:=False;
end;
