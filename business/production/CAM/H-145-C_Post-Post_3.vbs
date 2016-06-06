' Begin code for H-151-C Post-Post.vbs

'------------------------------------------------------------------------------
' Windows Script Host - VBScript
'------------------------------------------------------------------------------
' Name: Heidenhain Conversational PostPost Processor
' By: Collaborative Effort within CamBam User's Forum
' Version: 1.1
' Adapted from "Create Line-Numbered List" by: Harvey Colwell
' Copyright: (c) 2012,2013 All Rights Reserved!
' Freeware: No Warranty or Guarantee express or implied.
'
' USE OF THIS CODE MAY DAMAGE YOUR CONTROLLER, BRICK YOUR BRIDGEPORT AND KILL
' YOUR CAT! THE AUTHORS CAN TAKE NO RESPONSIBILITY FOR ANY OF THESE EVENTS, NOT
' EVEN THE UNTIMELY DEMISE OF YOUR CAT. Sorry & all that.
'
' This program adds line numbers as required by Heidenhain
' controllers and corrects various things the CamBam post-processor
' can't do - see inline comments for details.
' Code specifically written for use with CamBam
' CAM software to Heidenhain 151B controller (or equivalent).
'
' Takes the post file from CamBam with the Heidenhain 151B
' post processor (filename.nc) and adds line numbers and corrections
' beginning with the first line, and saves the
' output file as "filename.H"
'------------------------------------------------------------------------------
Option Explicit     'Ensure any variables are defined BEFORE they are used.

Dim oWS, oFS

Set oWS = WScript.CreateObject("WScript.Shell")
Set oFS = WScript.CreateObject("Scripting.FileSystemObject")

'----------
' Script Setup
'----------
Dim oInStream, oOutStream, sInFile, sOutFile, nTotalLines, sArg

'----------
' Process File(s)
'----------
If WScript.Arguments.Count = 0 Then
  If InStr(LCase(WScript.FullName), "cscript.exe") <> 0 Then
    sInFile = "StdIn"
    sOutFile = "StdOut"
    Set oInStream = WScript.StdIn
    Set oOutStream = WScript.StdOut
    Call ProcessFile
'CPR    Call ProcessFile2
  Else
    Call HelpMsg
  End If
Else
  For sArg = 0 To WScript.Arguments.Count - 1
    sInFile = WScript.Arguments(sArg)
    If IsFile(sInFile) Then
      sOutFile = Left(sInFile, InStrRev(sInFile, ".") - 1) & ".H.nc"
      Set oOutStream = oFS.OpenTextFile(sOutFile, 2, True, 0)
      Set oInStream = oFS.OpenTextFile(sInFile, 1)
      Call ProcessFile
      oWS.Run "NotePad.exe " & sOutFile
    Else
      WScript.Echo "File Not Found: " & sInFile, , "Error"
    End If
  Next
End If
Call CleanUp(0)

'------------------------------------------------------------------------------
' Subroutines
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
' Sub CleanUp: 
'
'   Close all streams & files, dispose of objects, prior to finishing.
'------------------------------------------------------------------------------
Sub CleanUp(exitCode)
    Set oInStream = Nothing
    Set oOutStream = Nothing
    Set oWS = Nothing
    Set oWS = Nothing
    WScript.Quit (exitCode)
End Sub


'------------------------------------------------------------------------------
' Sub ProcessFile: 
'
'   Does the actual work of this script, i.e. transforming the original
'   CamBam nc output into a file suitable for loading into a Heidenhain
'   TNC151x controller in Conversational mode.
'------------------------------------------------------------------------------
Sub ProcessFile()
    Dim sLine, nCount, rE, lastCC, lastTC, bSuppressCC, bSuppressTC, bSpiral
    Set rE = New RegExp 'Regular Expression parser
    nCount = 0
    lastCC = ""         'Last Centre Circle op
    lastTC = ""         'Last Tool Call op
    bSuppressCC=False   'Suppress CC flag
    bSuppressTC=False   'Suppress TC flag
    bSpiral = False     'Indicates we're in a Spiral Drilling MOp
    rE.global = True    'Regexes are global

    Do Until oInStream.AtEndOfStream
        bSuppressCC = False                 'Don't suppress this line unless told to do so later on.
        sLine = UCase(oInStream.ReadLine)   'Input line & conver to uppercase


        sLine = Replace(sLine,"MCPRMM","M")
        sLine = Replace(sLine,"MCPRM","M")


        'Replace I & J on CC definition with X and Y
        If Left(sLine,3)="CC " Then
            sLine=Replace(sLine," I"," X")
            sLine=Replace(sLine," J"," Y")
            If lastCC = sLine Then
                'Suppress this line (CC is same as previous CC = don't need to redefine it)
                bSuppressCC = True
            Else
                lastCC = sLine  'Store lastCC in case the next one can be suppressed.
            End If
        End If
        
        'Is this a spiral begin/end command?
        If sLine = "BEGIN SPIRAL" Then
            bSuppressCC = True
            bSpiral = True
        ElseIf sLine = "END SPIRAL" Then
            bSuppressCC = True
            bSpiral = False
        End If
        
        If bSpiral And Left(sLine,2) = "C " Then
            'Replace C X Y Z DR R F command with CP IPA+120 Z DR R F
            'Split into parts, remove X & Y parts replacing with new IPA part, then re-assemble
            Dim aC
            aC = Split(sLine," ")
            aC(0)="CP"
            If Left(aC(1),1) = "X" Then aC(1) = "IPA+120"
            If Left(aC(2),1) = "Y" Then aC(2) = ""
            sLine = Join(aC," ")
            sLine = Replace(sLine, "  ", " ")   'Remove the double-space...
        End If
        
        'Replace any instance of "ZR" with Z (occurs before a canned cycle)
        sLine=Replace(sLine," ZR"," Z")
       
        'Axis values must match X|Y|Z +|- N,NNN (or just N if no decimal points)
        'e.g. X+1 X+1,010 Z-2,000 are all valid
        '     X1 X1,000 X+1.010 Z2  are all invalid.

        'A "quick" note about regular expressions: These can be chuffing complicated. Luckily, the ones needed here are not 
        'too bad. Here's all you need to know about them:
        '
        ' If some chars are in square brackets (e.g. [XYZ]), then the regex will match if it finds one of those characters.
        ' You can refine the match by adding more of these - e.g. [XYZ][+-][0-9] will match X+1, Z-2, Y+3, etc. Putting a dash between 2 characters means "from 1st char to 2nd char", e.g. 0-9 = any number from 0 to 9; A-Z would mean any uppercase letter.
        ' You can search for groups of characters by adding *, ? or + after it, e.g. [XYZ][+-][0-9]+ will find Z+10, Y+20 ,Z-100, and so on. * means "zero or more", ?=0 or 1, + = 1 or more
        ' Putting an expression in brackets assigns it a "group number"; this is only important when you come to do the replace part of the regex.
        ' e.g. ([XYZ][+-][0-9]+) matches all of the above, and calls it $1 in the replace expression. Thus, by using ([XYZ][+-][0-9]+)[.]([0-9]) as our pattern,
        '   we are matching any axis, plus/minus, with any number of numbers as $1, followed by a full stop, followed by at least 1 number (which we call $2). So our replacement expression needs
        '   to keep the axis +/- number, change out the "." for a ",", and keep the trailing number; hence the expression $1,$2.
        '
    
        'Fix positive X,Y,Z references by inserting the "+" symbol
        rE.Pattern="([XYZ])([0-9])"         'Matches any of X Y or Z right next to a digit, e.g. X10, Y5, Z10.
        sLine = rE.Replace(sLine,"$1+$2")       'Replaces X10 with X+10, Y5 with Y+5 and Z10 with Z+10

        'Fix decimal points, from dot to comma
        ' Match including XYZ label axis, otherwise we trash any canned cycle definitions...
        rE.Pattern="([XYZ][+-][0-9]+)[.]([0-9])"    'Matches any number with an axis label & decimal point
        sLine = rE.Replace(sLine,"$1,$2")       'Replaces DP with a comma
                
        'For canned cycles, remove axis prefixes
        If Left(sLine,8)="CYCL DEF" Then
            sLine=Replace(sLine,"SET UP R","SET UP ")
            sLine=Replace(sLine,"DEPTH Z","DEPTH ")
            sLine=Replace(sLine,"PECKG Q","PECKG ")
            sLine=Replace(sLine,"PECKG Z","PECKG ") 'Non-pecking = peck the full Z height = gets a Z axis...
            sLine=Replace(sLine,"DWELL P","DWELL ")
        End If
        
        'Also for canned cycles; if there are any DWELL entries with no trailing number, set it to zero
        rE.Pattern="DWELL$"                             'Matches DWELL at the end of the line
        sLine = rE.Replace(sLine,"DWELL 0")             'Adds the zero
        
        'Did we set the "suppress toolchange" flag on the previous line? If so, THIS is the line we suppress (it will be the STOP command...)        
        If bSuppressTC then
            bSuppressCC = True
            bSuppressTC = False
        End If
        
        'Is this a tool call? When tool calling in drip feed, we need a TD, TC and STOP command in a row.
        'We can ignore the tool def, we need to find the tool call. If we find it AND it matches the previous TC, then suppress the STOP.
        rE.Pattern = "TOOL CALL [0-9]*"                 'Tool call
        If rE.Test(sLine) Then
            'Yep, Tool Call found... is it the same as the previous one?
            If lastTC <> "" Then    'If no previous tool call, ignore these tests, we need it...
                'If the only difference is the spindle speed, then we can ignore the stop. If the tool number or working axis changes, we can't....
                Dim aL, lA
                aL = Split(sLine," ") : lA = Split(lastTC," ")
                If aL(2) = lA(2) And aL(3) = lA(3) Then
                    'Tool No & Axis are the same, we can ignore the next STOP command
                    bSuppressTC = True
                Else
                    'Axis or tool number is different, so we cannot ignore the TC.
                End If
            Else
                'First TC... ignore it.
            End if
            
            'Set the lastTC value to this TC
            lastTC = sLine           
            
        End If
                
        If Not bSuppressCC Then
            oOutStream.WriteLine nCount & " " & sLine   'Write out the line, if not suppressed
            nCount = nCount + 1                         'Increment the line number
            If nCount > 9999 Then                       'Don't allow nCount to exceed 9999
                nCount = 1000
            End If
        End If
        
    Loop

End Sub


Sub ProcessFile2()
    Dim sLine, nCount, rE, lastCC, lastTC, bSuppressCC, bSuppressTC, bSpiral
    Set rE = New RegExp 'Regular Expression parser
    nCount = 0
    lastCC = ""         'Last Centre Circle op
    lastTC = ""         'Last Tool Call op
    bSuppressCC=False   'Suppress CC flag
    bSuppressTC=False   'Suppress TC flag
    bSpiral = False     'Indicates we're in a Spiral Drilling MOp
    rE.global = True    'Regexes are global

    Do Until oInStream.AtEndOfStream
        bSuppressCC = False                 'Don't suppress this line unless told to do so later on.
        sLine = UCase(oInStream.ReadLine)   'Input line & conver to uppercase

        sLine=Replace(sLine,"	 ","	")
        sLine=Replace(sLine," Y","Y")
        
    Loop

End Sub


'------------------------------------------------------------------------------
' Sub HelpMsg
'
'   Called if you run the script with no parameters.
'------------------------------------------------------------------------------
Sub HelpMsg()

MsgBox "Fixes up and adds line numbers to CamBam NC scripts generated with the" & vbCrLf & "Heidenhain TNC151 Conversational post-processor." & vbCrLf & vbCrLf & _
" cscript 'H-151-C Post-Post.vbs' InFile" & vbCrLf & _
" InFile is the filename of the nc code file to be line numbered",vbquestion,"Instructions"
Call CleanUp(1)
End Sub


'------------------------------------------------------------------------------
' Functions
'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
' Function IsFile(fName)
'
'   Returns true if fName is a valid filename
'------------------------------------------------------------------------------
Function IsFile(fName)
    If oFS.FileExists(fName) Then 
        IsFile = True 
    Else 
        IsFile = False
    End If
End Function


' End code
