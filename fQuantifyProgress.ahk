fQuantifyProgress(pFile) {
    oXML := ComObjCreate("MSXML2.DOMDocument.6.0")
	oXML.async := false
	oXML.preserveWhiteSpace := true

    oXML.load(pFile)
    fAbort(oXML.parseError.errorCode, A_ThisFunc, "Ошибка при чтении PXML-файла."
    , { "pFile": pFile, "oXML.parseError.errorCode": oXML.parseError.errorCode
    , "oXML.parseError.reason": oXML.parseError.reason })

    nSteelNodes := 0, isFlatFound := false, isBentFound := false, isExtraFound := false
    dOutput := {dTotal: {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
              , dExtra: {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
              , dBent:  {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}
              , dFlat:  {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}}

    For oSteel in oXML.selectNodes("/" ns("PXML_Document","Order","Product","Slab","Steel")) {
        nSteelNodes++
        sSteelType := "" ; "Extra", "Bent" or "Flat"
        dSteelOutput :=  {n10: 0, n8: 0, n6: 0, n5: 0, n4: 0}

        If (oSteel.getAttribute("Type") == "none") {
            fAbort(isExtraFound, A_ThisFunc, "Два комплекта усилении̌?", { "pFile": pFile }) 
            sSteelType := "Extra", isExtraFound := true
        } else fAbort((oSteel.getAttribute("Type") != "mesh"), A_ThisFunc
                , "This steel node's attribute isn't ""mesh"" or ""none"".", { pFile: pFile })

        For oBar in oSteel.selectNodes(ns("Bar")) {
            If (sSteelType == "Extra")
                fAbort((oBar.selectNodes(ns("Segment")).length > 1), A_ThisFunc
                ,"An extra reinforcement bar has more than one segment.")
            else if ( (sSteelType != "Bent") and (oBar.selectNodes(ns("Segment", "BendY")).length > 1) ) {
                fAbort(isBentFound, A_ThisFunc, "Две гнутые сетки?", { "pFile": pFile })
                sSteelType := "Bent", isBentFound := true
            }

            nBarQuan := oBar.selectSingleNode(ns("PieceCount")).text
            nBarDiam := oBar.selectSingleNode(ns("Diameter")).text
            nBarLeng := 0
            For oSegment in oBar.selectNodes(ns("Segment", "L"))
                nBarLeng += oSegment.text

            dSteelOutput[("n" nBarDiam)] += nBarLeng * nBarQuan
            dOutput.dTotal[("n" nBarDiam)] += nBarLeng * nBarQuan
        }
        
        If ((sSteelType != "Extra") and (sSteelType != "Bent")) {
            fAbort(isFlatFound, A_ThisFunc, "Две плоские сетки?", { "pFile": pFile })
            sSteelType := "Flat", isFlatFound := true
        }

        dOutput[("d" sSteelType)] := dSteelOutput.Clone()
    }

    fAbort(nSteelNodes == 0, A_ThisFunc, "Сетки не наи̌дены.", { "pFile": pFile }) 
    fAbort(nSteelNodes > 3, A_ThisFunc, "Наи̌дены три сетки.", { "pFile": pFile })

    return dOutput
}

ns(aNodeNames*) { ; Some XML namespace bullshit
    Local
    sSelector := ""
    For idx, sNodeName in aNodeNames {
        If (A_Index > 1)
            sSelector .= "/"
        sSelector .= "*[namespace-uri()=""http://progress-m.com/ProgressXML/Version1"" and local-name()=""" sNodeName """]"
    }
    return sSelector
}