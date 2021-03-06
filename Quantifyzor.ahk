#NoEnv
#Warn
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
StringCaseSense On
AutoTrim Off

;@Ahk2Exe-SetName Quantifyzor
;@Ahk2Exe-SetDescription Like abacus but better.
;@Ahk2Exe-SetMainIcon Things\Quantifyzor.ico
;@Ahk2Exe-SetCompanyName Konovalenko Systems
;@Ahk2Exe-SetCopyright Eli Konovalenko
;@Ahk2Exe-SetVersion 1.0.2

#Include fQuantifyUnitechnik.ahk
#Include fQuantifyProgress.ahk

If !(  (A_ComputerName == "160037-MMR" and InStr(FileExist("C:\Progress\MSystem\Impdata\DSK\SuperCoolSecretAwesomeStuff"), "D", true)   )
    or (A_ComputerName == "160037-BGM" and InStr(FileExist("C:\Progress\MSystem\Temp\645ff040-5081-101b\Microsoft\default"), "D", true) )
    or (A_ComputerName == "MAYTINHXACHTAY")) {
	MsgBox, 16, Stop right there`, criminal scum!, You are doing something you shouldn't.
	ExitApp
}

Global oOutputA := "", oOutputB := "", oLogger := new cLogger

oLogger.del([ "OutputA", "OutputB", "SkippedA", "SkippedB", "Comparison" ])

pInputDirA := "", pInputDirB := ""
Loop, files, % A_ScriptDir "\*", D
{
    If RegExMatch(A_LoopFileName, "xS)^Input (?<letter> [AB]) \s", sInput_) {
        fAbort( pInputDir%sInput_letter% , "Quantifyzor", "Две папки «Input" sInput_letter "».")
        pInputDir%sInput_letter% := A_LoopFileLongPath
    }
}

oOutputA := pInputDirA ? fQuantify(pInputDirA, "A") : ""
oOutputB := pInputDirB ? fQuantify(pInputDirB, "B") : ""

dPanelList := {}
If (oOutputA or oOutputB) {
    dPanelList := fCompare(oOutputA, oOutputB)

    oLogger.save([ "OutputA", "OutputB", "SkippedA", "SkippedB", "Comparison" ])

    MsgBox, 4160, % dPanelList.Count() " чертежей", % "  Вы воспользовались бесплатнои̌ версиеи̌ Quantifyzor™!`n"
    . "Благодарим за доверие, которое Вы оказываете нашеи̌ продукции.`n`n"
    . "                                                                   «Konovalenko Systems»™"
}

ExitApp


;########################################## Functions #############################################;
fQuantify(pInputDir, sLetter) {
    Local
    Global oLogger

    nFilesTotal := 0, nPanelsTotal := 0, nFilesSkipped := 0, dSumTotal := { n10: 0, n8: 0, n6: 0, n5: 0, n4: 0 }
    oOutput := ComObjCreate("Scripting.Dictionary") ; Have to use this bullshit, cause AHK was "designed to be case-insensitive", you see.

    Loop, files, % pInputDir "\*", R
    {
        ; dPanel :={sName: sPanel, pFile: A_LoopFileLongPath
        ;         , dTotal: {n10: "", n8: "", n6: "", n5: "", n4: ""}
        ;         , dExtra: {...}, dBent: {...}, dFlat: {...}}
        nFilesTotal++

        sPanel := fGetPanelNameFilePath(A_LoopFileLongPath)
        If !sPanel {
            nFilesSkipped++
            oLogger.add("Skipped" sLetter, "UNKNOWN PANEL", A_LoopFileDir "\", A_LoopFileName)
            continue
        }
        If (oOutput.Exists(sPanel) == -1)
            fAbort(true, A_ThisFunc, "Множественные версии однои̌ панели не принимаются."
            , { "sPanel": sPanel, "A_LoopFileLongPath": A_LoopFileLongPath, "oOutput.Item[""" sPanel """].pFile": oOutput.Item[sPanel].pFile } )


        If ( (A_LoopFileExt == "pxml") or (A_LoopFileExt == "PXML") ) {
            dPanel := fQuantifyProgress(A_LoopFileLongPath)
		} else if (A_LoopFileExt == "") {
            dPanel := fQuantifyUnitechnik(A_LoopFileLongPath)
        } else {
            nFilesSkipped++
			oLogger.add("Skipped" sLetter, "WRONG EXTENSION", A_LoopFileDir "\", A_LoopFileName)
			continue
        }
        nCheck := 0
        For _, nValue in dPanel.dTotal
            nCheck += nValue
        fAbort(!nCheck, A_ThisFunc, "Общая длина проволоки равна нулю.", {"A_LoopFileLongPath": A_LoopFileLongPath})

        For key, value in dPanel.dTotal
            dSumTotal[key] += value

        nPanelsTotal++
        dPanel.sName := sPanel, dPanel.pFile := A_LoopFileLongPath
        oOutput.Add(sPanel, dPanel)
        oLogger.add("Output" sLetter, sPanel, dPanel.dTotal.n10, dPanel.dTotal.n8, dPanel.dTotal.n6, dPanel.dTotal.n5, dPanel.dTotal.n4)
    }

    fAbort(nFilesTotal != ( nPanelsTotal + nFilesSkipped ), A_ThisFunc, "Что-то не сходится."
	, { "nFilesTotal": nFilesTotal, "nPanelsTotal": nPanelsTotal, "nFilesSkipped": nFilesSkipped })

    oLogger.add("Output" sLetter, "#Sum:", dSumTotal.n10, dSumTotal.n8, dSumTotal.n6, dSumTotal.n5, dSumTotal.n4, "`n")

    return oOutput
}

fCompare(oOutputA, oOutputB) {
    Local
    Global oLogger    

    dCombinedPanelList := {}, dSumTotal := { n10: 0, n8: 0, n6: 0, n5: 0, n4: 0 }

    For sName in oOutputA.Keys
        dCombinedPanelList[sName] := 0

    For sName in oOutputB.Keys
        If !dCombinedPanelList.HasKey(sName)
            dCombinedPanelList[sName] := 0

    For sName, _ in dCombinedPanelList {

        If ( !oOutputB.Exists(sName) )
            n10B := 0, n8B := 0, n6B := 0, n5B := 0, n4B := 0
        else for key, value in oOutputB.Item[sName].dTotal
            %key%B := value

        If (!oOutputA.Exists(sName))
            n10A := 0, n8A := 0, n6A := 0, n5A := 0, n4A := 0
        else for key, value in oOutputA.Item[sName].dTotal
            %key%A := value

        For _, d in [10, 8, 6, 5, 4] { ; Wire diameters.
            c := n%d%B - n%d%A                 ; The difference between B and A.
            nDelta%d% := (c < 0) ? c : ("+" c) ; If zero or above add «+».
            dSumTotal[("n" d)] += c               ; Add the difference to the respective diameter's key in dSumTotal.
        }        

        oLogger.add("Comparison", sName, nDelta10, nDelta8, nDelta6, nDelta5, nDelta4)
    }

    For key, value in dSumTotal
        dSumTotal[key] := (value < 0) ? value : ("+" value)
    oLogger.add("Comparison", "#Sum:", dSumTotal.n10, dSumTotal.n8, dSumTotal.n6, dSumTotal.n5, dSumTotal.n4, "`n")

    return dCombinedPanelList
}




; Tries to get panel name from its file name, if fails returns empty string.
fGetPanelNameFilePath(pFile) {
    Local

    SplitPath, pFile, sFileName, pDir, sExt, sFileNameBare

    ;!!!!!!!!!!!!!!!!!!!  vvv  LATIN => CYRILLIC   vvv  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
    aLatinToCyrillic := [ ["ixS) (?<!\.) [a-zа-я]++.", "$U0"] ; Capitalizes everything except file extensions
    , ["^V-", "В-"], ["^VK-", "ВК-"], ["^VC-", "ВЦ-"], ["^VT-", "ВТ-"], ["^NS-", "НС-"], ["^NT-", "НТ-"], ["^NC-", "НЦ-"]
    , ["^P-", "П-"], ["^PV-", "ПВ-"], ["^PG-", "ПГ-"], ["^PK-", "ПК-"], ["^PL-", "ПЛ-"], ["^PT-", "ПТ-"], ["^PC-", "ПЦ-"]
    , ["^SV-", "СВ-"], ["^SVSH-", "СВШ-"], ["^SSH-", "СШ-"], ["^PTKR-", "ПТКР-"], ["^KR-", "КР-"], ["^Z-", "Я-"] ]

    For _, aPair in aLatinToCyrillic
        sFileNameBare := RegExReplace( sFileNameBare, aPair[1], aPair[2] )
    ;!!!!!!!!!!!!!!!!!!!  ^^^  LATIN => CYRILLIC    ^^^  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
    
    nPos := RegExMatch(sFileNameBare , "isSx)^\d? (?<type> [А-Я]{1,6} | В\(к\)) - (?<num1> \d+) (?<num2> -\d+)?", sPanel_)
	fAbort(ErrorLevel, A_ThisFunc, "Regex error.")
    If !nPos
        return ""    
    If ( (sPanel_num2 != "") and (LTrim(sPanel_num1, "0") != LTrim(SubStr(sPanel_num2, 2), "0")) )
	    return ""
    
    sPanelType := (sPanel_type == "В(к)") ? "ВК" : sPanel_type
    StringUpper, sPanelType, sPanelType
    sPanel := sPanelType "-" LTrim(sPanel_num1, "0") ; Removing leading zeroes.

    return sPanel
}

; Calls ExitApp if the condition is true. Shows a message and given vars.
fAbort(isCondition, sFuncName, sNote, dVars:="") {
	If isCondition {
		sAbortMessage := % sFuncName ": " sNote
		. "`n`nA_LineNumber: """ A_LineNumber """`nErrorLevel: """ ErrorLevel """`nA_LastError: """ A_LastError """`n"
		For sName, sValue in dVars
			sAbortMessage .= "`n" sName ": """ sValue """"
		MsgBox, 16,, % sAbortMessage
		ExitApp
	}
}

; Takes an object, returns string.
fObjToStr(obj) {
	If !IsObject(obj)
		return obj
	str := "`n{"
	For key, value in obj
		str .= "`n    " key ": " fObjToStr(value) ","
	return str "`n}"
}

class cLogger {
	static sColEnd := "ø", sRowEnd := "ż"
	; Takes the log's name and a variable number of column entries.
	add(log, cols*) {
		For idx, col in cols
			this[log] .= col . (idx < cols.MaxIndex() ? this.sColEnd : this.sRowEnd)
	}
	; Takes an array of log names; sorts, pads, saves (replacing old). If a log name
	; is empty, just deletes the file (if exists). 
	save(aLogs) {                                             ; MsgBox % "cLogger.save()"		
		If !isObject(aLogs)
			return                                            ; MsgBox % "cLogger.save(): isObject = true"		
		For idx, log in aLogs {		
			If (this[log] == "") {
				this.del(log)
				continue
			}                                                  ; MsgBox % "sSortedLog: """ sSortedLog """"			
			sSortedLog := this[log], sRowEnd := this.sRowEnd
			Sort, sSortedLog, F fNaturalSort D%sRowEnd%
			
			sPaddedLog := "", pad := []		
			Loop, parse, sSortedLog, % this.sRowEnd
				Loop, parse, A_LoopField, % this.sColEnd
					If (pad[A_Index] < StrLen(A_LoopField))
						pad[A_Index] := StrLen(A_LoopField)
					
			Loop, parse, sSortedLog, % this.sRowEnd
			{
				Loop, parse, A_LoopField, % this.sColEnd
					sPaddedLog .= Format("{:-" pad[A_Index] + 3 "}", A_LoopField)
				sPaddedLog .= "`r`n"
			}

			oLogFile := FileOpen(log ".log", "w-rwd")
			fAbort(!oLogFile, A_ThisFunc, "Ошибка при открытии """ log ".log"".")
			oLogFile.Write(sPaddedLog)
			oLogFile.Close()
		}
	}
	; Takes an array of log names; removes them from the logger object
	; and deletes the files.
	del(aLogs) {
		If !isObject(aLogs)
			return
		For idx, log in aLogs {			
			If FileExist(log ".log") {
				this[log] := ""
				FileDelete, % log ".log"
				fAbort(ErrorLevel, A_ThisFunc, "Ошибка при удалении """ log ".log"".")
			}
		}
	}
}

; Natural sort: digits in filenames are grouped into numbers.
fNaturalSort(a, b) {
	return DllCall("shlwapi.dll\StrCmpLogicalW", "ptr", &a, "ptr", &b, "int")
}