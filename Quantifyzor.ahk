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
;@Ahk2Exe-SetVersion 1.0

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

If (InStr(FileExist("InputA"), "D", true))
    oOutputA := fQuantify(A_ScriptDir "\InputA", "A")    

If (InStr(FileExist("InputB"), "D", true))
    oOutputB := fQuantify(A_ScriptDir "\InputB", "B")    

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

    nTotalFiles := 0, nPanelFiles := 0, nSkippedFiles := 0
    dSumTotal := { n10: 0, n8: 0, n6: 0, n5: 0, n4: 0 }
    oOutput := ComObjCreate("Scripting.Dictionary") ; Have to use this bullshit, cause AHK was "designed to be case-insensitive", you see.

    Loop, files, % pInputDir "\*", R
    {
        ; dPanel :={sName: sPanelName, pLoco: A_LoopFileLongPath
        ;         , dTotal: {n10: "", n8: "", n6: "", n5: "", n4: ""}
        ;         , dExtra: {...}, dBent: {...}, dFlat: {...}}
        nTotalFiles++

        sPanelName := fGetPanelName(A_LoopFileLongPath)
        If !sPanelName {
            nSkippedFiles++
            oLogger.add("Skipped" sLetter, "UNKNOWN PANEL", A_LoopFileDir "\", A_LoopFileName)
            continue
        }
        If (oOutput.Exists(sPanelName) == -1)
            fAbort(true, A_ThisFunc, "Множественные версии однои̌ панели не принимаются."
            , { "sPanelName": sPanelName, "A_LoopFileLongPath": A_LoopFileLongPath
            , "oOutput.Item[""" sPanelName """].pLoco": oOutput.Item[sPanelName].pLoco } )


        If (A_LoopFileExt == "pxml") {
            dPanel := fQuantifyProgress(A_LoopFileLongPath)
		} else if (A_LoopFileExt == "") {
            dPanel := fQuantifyUnitechnik(A_LoopFileLongPath)
        } else {
            nSkippedFiles++
			oLogger.add("Skipped" sLetter, "WRONG EXTENSION", A_LoopFileDir "\", A_LoopFileName)
			continue
        }
        nCheck := 0
        For _, nValue in dPanel.dTotal
            nCheck += nValue
        fAbort(!nCheck, A_ThisFunc, "Отсутствуют данные о длине.", {"A_LoopFileLongPath": A_LoopFileLongPath})

        For key, value in dPanel.dTotal
            dSumTotal[key] += value

        nPanelFiles++
        dPanel.sName := sPanelName, dPanel.pLoco := A_LoopFileLongPath
        oOutput.Add(sPanelName, dPanel)
        oLogger.add("Output" sLetter, sPanelName
        , dPanel.dTotal.n10, dPanel.dTotal.n8, dPanel.dTotal.n6, dPanel.dTotal.n5, dPanel.dTotal.n4)
    }

    fAbort(nTotalFiles != ( nPanelFiles + nSkippedFiles ), A_ThisFunc, "Что-то не сходится."
	, { "nTotalFiles": nTotalFiles, "nPanelFiles": nPanelFiles, "nSkippedFiles": nSkippedFiles })

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

        If (!oOutputB.Exists(sName))
            n10B := 0, n8B := 0, n6B := 0, n5B := 0, n4B := 0
        else for key, value in oOutputB.Item[sName].dTotal
            %key%B := value

        If (!oOutputA.Exists(sName))
            n10A := 0, n8A := 0, n6A := 0, n5A := 0, n4A := 0
        else for key, value in oOutputA.Item[sName].dTotal
            %key%A := value

        For _, d in [10, 8, 6, 5, 4] {
            c := n%d%B - n%d%A
            dSumTotal[("n" d)] += c
            nDelta%d% := (c < 0) ? c : ("+" c)
        }        

        oLogger.add("Comparison", sName, nDelta10, nDelta8, nDelta6, nDelta5, nDelta4)
    }

    For key, value in dSumTotal
        dSumTotal[key] := (value < 0) ? value : ("+" value)
    oLogger.add("Comparison", "#Sum:", dSumTotal.n10, dSumTotal.n8, dSumTotal.n6, dSumTotal.n5, dSumTotal.n4, "`n")

    return dCombinedPanelList
}

fGetPanelName(pFile) {
    SplitPath, pFile, sFileName, pDir, sExt, sFileNameBare
    
    nPos := RegExMatch(sFileNameBare
    , "isSx)^\d? (?<type> [A-ZА-Я]{1,6}) - (?<num1> \d+) (?<num2> -\d+)?", sPanel_)
	fAbort(ErrorLevel, A_ThisFunc, "RegExMatch error.")
    If !nPos
        return ""
    
    If ( (sPanel_num2 != "")
		and (LTrim(sPanel_num1, "0") != LTrim(SubStr(sPanel_num2, 2), "0")) )
	return ""

    sPanelType := RegExMatch(sPanel_type, "iS)[А-Я]") ? fTransliterate(sPanel_type) : sPanel_type
    sPanelName := sPanelType "-" LTrim(sPanel_num1, "0") ; Removing leading zeroes.

    return sPanelName
}

fTransliterate(str) {
    Local
    dRusToEng := {"А": "A", "Б": "B", "В": "V", "Г": "G", "Д": "D", "Е": "Je", "Ё": "Jo", "Ж": "Zh", "З": "Z", "И": "I"
				 ,"Й": "J", "К": "K", "Л": "L", "М": "M", "Н": "N", "О": "O", "П": "P", "Р": "R", "С": "S", "Т": "T"
				 ,"У": "U", "Ф": "F", "Х": "H", "Ц": "C", "Ч": "Ch", "Ш": "Sh", "Щ": "Shch", "Ъ": "bitch you crazy"
				 ,"Ы": "Y", "Ь": "waat", "Э": "E", "Ю": "Ju", "Я": "Ja"}
    newStr := "", char := ""
    Loop, parse, str
    {
        StringUpper, char, A_LoopField
        If RegExMatch(char, "S)[А-Я]")
            newStr .= dRusToEng[char]
        else
            newStr .= char
    }
    return newStr
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