  ;=== global variables
  Global PassText
  Global AreaStatus
  AreaStatus := 8

  ;=== GUI creation
  Gui, Dropper: New
  Gui, Dropper: Font, s12 w200,MS Sans Serif
  Gui, Dropper: Add, Edit, y10 x10 w533 h30 gPassEvent -multi -wrap vPassEdit
  Gui, Dropper: Font, s30 w700,Webdings
  Gui, Dropper: Add, Text, y46 x10 w533 center vAreaPass, ggggggggggggg
  Gui, Dropper: Add, Text, y90 x10 w533 center vAreaYes, ggggggggggggg
  Gui, Dropper: Add, Text, y134 x10 w533 center vAreaNo, ggggggggggggg
  Gui, Dropper: Font, s18 w700,MS Sans Serif
  Gui, Dropper: Add, Text, y51 x10 w530 h38 center BackgroundTrans vTextPass, DROP: Directory (encrypted protected)
  Gui, Dropper: Add, Text, y95 x10 w530 h38 center BackgroundTrans vTextYes, DROP: Directory (encrypted not protected)
  Gui, Dropper: Add, Text, y139 x10 w530 h38 center BackgroundTrans vTextNo, DROP: Directory (not encrypted)
  Gui, Dropper: Font, s10 w700,MS Sans Serif
  Gui, Dropper: Add, Text, y183 x10 w533 center vLabel, Ready, please drop a directory
  Gui, Color,, cFFFFFF
  RefreshAreas(1)
  Gui, Dropper: Show, w553 h207 Center, Extractor Builder
  GuiControl, Focus, Dummy
  return

;=== password event
PassEvent:
  if (A_GuiEvent = "Normal")
  {
    Gui, Submit, NoHide
    PassText := PassEdit
    RefreshAreas(1)
  }
  return

;=== GUI close
DropperGuiClose:
  ExitApp

;=== refresh areas
RefreshAreas(RefreshStatus)
{
  if (RefreshStatus = 1 and PassText <> "")
    RefreshStatus := 2
  if (AreaStatus <> RefreshStatus)
  {
    if (RefreshStatus = 0)
      Gui, Font, cFF7777 s30 w700,Webdings
    else if (RefreshStatus = 1)
      Gui, Font, cCCCCCC s30 w700,Webdings
    else
      Gui, Font, c77FF77 s30 w700,Webdings
    GuiControl, Font, AreaPass
    Gui, Font, c000000 s18 w700,MS Sans Serif
    GuiControl, Font, TextPass
  }
  if ((AreaStatus = 0 and RefreshStatus <> 0) or (AreaStatus <> 0 and RefreshStatus = 0) or (AreaStatus = 8))
  {
    if (RefreshStatus = 0)
      Gui, Font, cFF7777 s30 w700,Webdings
    else
      Gui, Font, c77FF77 s30 w700,Webdings
    GuiControl, Font, AreaYes
    GuiControl, Font, AreaNo
    Gui, Font, c000000 s18 w700,MS Sans Serif
    GuiControl, Font, TextYes
    GuiControl, Font, TextNo
  }
  AreaStatus := RefreshStatus
}

;=== GUI drop files
DropperGuiDropFiles:
  DropAction := 0
  if ((A_GuiControl = "AreaPass" or A_GuiControl = "TextPass") and PassText <> "")
    DropAction := 3
  if (A_GuiControl = "AreaYes" or A_GuiControl = "TextYes")
    DropAction := 2
  if (A_GuiControl = "AreaNo" or A_GuiControl = "TextNo")
    DropAction := 1
  if (DropAction > 0)
  {
    GuiControl,, Label, Processing, please wait ...
    RefreshAreas(0)
    Loop, parse, A_GuiEvent, `n
    {
	  try
	    FileGetAttrib,DropAttrib,%A_LoopField%
      catch e
        DropAttrib := "Z"
	  if InStr(DropAttrib, "D")
        DropAttrib := ExecuteBuild(A_LoopField, DropAction)
    }
    RefreshAreas(1)
    GuiControl,, Label, Ready, please drop a directory
  }
  return

ExecuteBuild(ExecuteDir, ExecuteAction)
{
  ;=== delete work files
  FileDelete,result.7z
  FileDelete,config.txt
  FileDelete,archive.7z
  ;=== special strings
  ExecuteQuote := """"
  ExecuteNewline := "`n"
  ExecuteTitle := ExecuteDir
  ExecutePosition := InStr(ExecuteTitle,"\")
  while (ExecutePosition > 0)
  {
    StringMid,ExecuteTitle,ExecuteTitle,ExecutePosition + 1
    ExecutePosition := InStr(ExecuteTitle,"\")
  }
  ;=== create archive.7z
  if (ExecuteAction = 1)
    ExecuteTask := ExecuteQuote . "7za.exe" . ExecuteQuote . " a -r archive.7z " . ExecuteQuote . ExecuteDir . ExecuteQuote
  else
  {
    ExecuteTask := "Extractor"
    if (ExecuteAction = 3)
      ExecuteTask := PassText
    ExecuteTask := ExecuteQuote . "7za.exe" . ExecuteQuote . " a -r -p" . ExecuteTask . " archive.7z " . ExecuteQuote . ExecuteDir . ExecuteQuote
  }
  RunWait,%ExecuteTask%,,hide
  if (ExecuteAction <> 1)
  {
    ExecuteTask := ExecuteQuote . "7za.exe" . ExecuteQuote . " a result.7z archive.7z 7zG.exe 7z.dll"
    RunWait,%ExecuteTask%,,hide
    FileMove,result.7z,archive.7z,1
  }
  ;=== create config.txt
  ExecuteTarget := FileOpen("config.txt","w")
  ExecuteBuffer := ";!@Install@!UTF-8!" . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  if (ExecuteAction = 1)
    ExecuteBuffer := "InstallPath=" . ExecuteQuote . "." . ExecuteQuote . ExecuteNewline
  else
  {
    ExecuteBuffer := "ExecuteFile=" . ExecuteQuote . "7zG.exe" . ExecuteQuote . ExecuteNewline
    ExecuteTarget.write(ExecuteBuffer)
    ExecuteBuffer := "-PExtractor "
    if (ExecuteAction = 3)
      ExecuteBuffer := ""
    ExecuteBuffer := "ExecuteParameters=" . ExecuteQuote . "x " . ExecuteBuffer . "-o\" . ExecuteQuote "%%S\" . ExecuteQuote . " archive.7z" . ExecuteQuote . ExecuteNewline
  }
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteBuffer := "Title=" . ExecuteQuote . ExecuteTitle . ExecuteQuote . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteBuffer := "ExtractDialogText=" . ExecuteQuote . "Extracting to current directory ..." . ExecuteQuote . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteBuffer := "FinishMessage=" . ExecuteQuote . "Extracted to current directory" . ExecuteQuote . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteBuffer := "GUIMode=" . ExecuteQuote . "1" . ExecuteQuote . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteBuffer := ";!@InstallEnd@!" . ExecuteNewline
  ExecuteTarget.write(ExecuteBuffer)
  ExecuteTarget.close
  ;=== open target file
  ExecuteBuffer := ExecuteDir . ".exe"
  FileDelete,%ExecuteBuffer%
  ExecuteTarget := FileOpen(ExecuteBuffer,"w")
  ;=== binary copy 7zsd_LZMA-EBico.sfx
  ExecuteSource := FileOpen("7zsd_LZMA-EBico.sfx","r")
  ExecuteSize := ExecuteSource.Length
  ExecuteSource.RawRead(ExecuteBuffer, ExecuteSize)
  ExecuteTarget.RawWrite(ExecuteBuffer, ExecuteSize)
  ExecuteSource.close
  ;=== binary copy config.txt
  ExecuteSource := FileOpen("config.txt","r")
  ExecuteSize := ExecuteSource.Length
  ExecuteSource.RawRead(ExecuteBuffer, ExecuteSize)
  ExecuteTarget.RawWrite(ExecuteBuffer, ExecuteSize)
  ExecuteSource.close
  ;=== binary copy archive.7z
  ExecuteSource := FileOpen("archive.7z","r")
  ExecuteSize := ExecuteSource.Length
  while (ExecuteSize > 8192)
  {
    ExecuteSource.RawRead(ExecuteBuffer, 8192)
    ExecuteTarget.RawWrite(ExecuteBuffer, 8192)
	ExecuteSize := ExecuteSize - 8192
  }
  if (ExecuteSize > 0)
  {
    ExecuteSource.RawRead(ExecuteBuffer, ExecuteSize)
    ExecuteTarget.RawWrite(ExecuteBuffer, ExecuteSize)
  }
  ExecuteSource.close
  ;=== close target file
  ExecuteTarget.close
  ;=== delete work files
  FileDelete,config.txt
  FileDelete,archive.7z
}
