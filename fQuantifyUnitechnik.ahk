fQuantifyUnitechnik(pFile) {
    oFile := FileOpen(pFile, "r-rwd", "CP1251")
    sUnitechnik := oFile.Read()
    oFile.Close()
    fAbort(sUnitechnik == "", A_ThisFunc, "Ошибка при чтении файла.", { "pFile": pFile, "sUnitechnik": sUnitechnik })
    
    dOutput := {dTotal: {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
                    , dExtra: {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
                    , dBent:  {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
                    , dFlat:   {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}}

    nPos := RegExMatch(sUnitechnik, "sSx)^"
    . "(?<top>   HEADER__\r?\n600\r?\n (?: [^E]++ | E (?!ND\r?\n  (RODSTOCK|BRGIRDER|REFORCEM) ) )++ END\r?\n)"
    . "(?<extra> RODSTOCK\r?\n         (?: [^E]++ | E (?!ND\r?\n  (         BRGIRDER|REFORCEM) ) )++ END\r?\n)?+"
    . "(?:       BRGIRDER\r?\n         (?: [^E]++ | E (?!ND\r?\n                     REFORCEM  ) )++ END\r?\n)?+"
    . "(?<mid>   REFORCEM\r?\n600\r?\n (?: [^E]++ | E (?!ND\r?\n   STEELMAT                    ) )++ END\r?\n)"
    . "(?<mat1>  STEELMAT\r?\n         (?: [^E]++ | E (?!ND\sSTEELMAT                          ) )++ END\sSTEELMAT\r?\n)"
    . "(?<mat2>  (?&mat1))?+"
    . "(?<mat3>  (?&mat1))?+"
    . "(?<bot>   END\sREFORCEM\r?\nEND\sSLABDATE\r?\nEND\sHEADER__)$", sMatch_)

    fAbort(!nPos, A_ThisFunc, "Содержимое фаи̌ла не опознано.", { "pFile": pFile })			
    fAbort(sMatch_mat1 == "", A_ThisFunc, "Сетки не наи̌дены.", { "pFile": pFile }) 
    fAbort(sMatch_mat3 != "", A_ThisFunc, "Наи̌дены три сетки.", { "pFile": pFile })

    sBendingRegex := "xS)\s00[12]\r?\n"
				   . "   \d{3}  (?:\s\d{5}){4}  \s([01][0-8]\d)  \s\d{3}  (?:\s\d{5}){4}  \s(?1)  \s[+-](?1)"
    isFlatFound := false, isBentFound := false, isExtraFound := false

    For _, sBlock in [sMatch_extra, sMatch_mat1, sMatch_mat2] {
        If !sBlock
            continue

        sBlockType := "" ; "Extra", "Bent" or "Flat"
        dBlockOutput :=  {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}

        If (InStr(sBlock, "STEELMAT", true)) {
            If RegExMatch(sBlock, sBendingRegex) {
                fAbort(isBentFound, A_ThisFunc, "Две гнутые сетки?", { "pFile": pFile })
                sBlockType := "Bent", isBentFound := true
            } else {
                fAbort(isFlatFound, A_ThisFunc, "Две плоские сетки?", { "pFile": pFile })
                sBlockType := "Flat", isFlatFound := true
            }
        } else {
            fAbort(isExtraFound, A_ThisFunc, "Два комплекта усилении̌?", { "pFile": pFile }) 
            sBlockType := "Extra", isExtraFound := true
        }

        Loop, parse, sBlock, `n, `r
        {
            If (StrLen(A_LoopField) < 75) 
                continue
            nBarQuan := 0 + SubStr(A_LoopField, 22, 5)
            nBarDiam := LTrim(SubStr(A_LoopField, 28, 3), "0")
            nBarLeng := 0 + SubStr(A_LoopField, 32, 5)

            dBlockOutput[("n" nBarDiam)] += nBarQuan * nBarLeng
            dOutput.dTotal[("n" nBarDiam)] += nBarQuan * nBarLeng
        }
        
        dOutput[("d" sBlockType)] := dBlockOutput.Clone()
    }

    return dOutput
}