Include (%sySystem, %occFile)

Class src.maker Extends %RegisteredObject
{

Parameter Root = "D:\temp";

Parameter ImportName = "src.maker-v0.0.1";

Parameter SourceFolder = "src";

Property Project As %String;

Property Extension As %String [ InitialExpression = "cls" ];

Property Package As %String [ Required ];

Property Namespace As %String [ Required ];

ClassMethod Execute(pNamespace As %String = "", pPackage As %String, pProject As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set:pNamespace="" pNamespace = $Namespace
		Set:pProject="" pProject = pPackage
		Set src = ..%New(pNamespace, pPackage, pProject)
		$$$THROWONERROR(tSC, src.CreateClassFiles())
		
	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	Quit tSC
}

Method CreateClassFiles() As %Status
{
	Set tSC = $$$OK
	Try {
		$$$THROWONERROR(tSC, ..Export())
		$$$THROWONERROR(tSC, ..GetPackageClasses(.tRS))
		While tRS.%Next() {
			Set clsname = tRS.%Get("Name") 
			$$$THROWONERROR(tSC, ..FileGenerate(clsname))
		}
	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	Quit tSC
}

Method FileName(pClassName As %String) As %String
{
	Set clss = $ListFromString(pClassName,".")
	Set $List(clss,*)= $List(clss,*) _ "." _ ..Extension
	
	Set $List(tempPath, *+1) = ..#Root
	Set $List(tempPath, *+1) = ..Project
	Set $List(tempPath, *+1) = ..#SourceFolder
	Set $List(tempPath, *+1) = $ListToString(clss,"\")
	
	Quit $ListToString(tempPath, "\")
}

Method FileGenerate(pClassName As %String) As %Status [ Private ]
{
	Set tSC = $$$OK
	Try {
		$$$THROWONERROR(tSC, ##class(%Compiler.UDL.TextServices).GetTextAsStream(..Namespace, pClassName,.tStream))
		#dim tStream As %Stream.Character

		Set filename = ..FileName(pClassName),
			tempPath = $ListFromString(filename,"\")
		Set $List(tempPath, *)="", tempPath = $Extract($ListToString(tempPath,"\"),0,*-1)

		$$$THROWONERROR(tSC, ..CreateDirectoryRecurse(tempPath))
		
		Set file=##class(%File).%New(filename)
		Do file.Open("WSN"), tStream.Rewind()
		While 'tStream.AtEnd {
   			$$$THROWONERROR(tSC, file.WriteLine(tStream.ReadLine()))
  		}
		Do file.Close()
		
        
	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	Quit tSC
}

Method GetPackageClasses(Output tRS As %SQL.StatementResult) As %Status [ Private ]
{
	Set tSC = $$$OK, ns = $Namespace
	Try {
		
		Set sql = "Select Name FROM %Dictionary.ClassDefinition " _ 
			"Where Name %STARTSWITH ?"
				
		Set statement = ##class(%SQL.Statement).%New(), tRS = ""
		Set tSC = statement.%Prepare(sql)
		Set pkg = ..Package
		
		ZNSpace ..Namespace

		Set tRS = statement.%Execute(pkg)
		
	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	
	ZNSpace ns	
	Quit tSC
}

Method %OnNew(pNamespace As %String = "", pPackage As %String = "", pProject As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	Set:pNamespace'="" ..Namespace = pNamespace
	Set:pProject'='"" ..Project = pProject
	Set:pPackage'='"" ..Package = pPackage
	Quit $$$OK
}

Method Export() As %Status [ Private ]
{
	Set tSC = $$$OK, ns = $Namespace
	Try {
		Set $List(tempPath, *+1) = ..#Root
		Set $List(tempPath, *+1) = ..Project
		Set $List(tempPath, *+1) = ..#ImportName _".xml"
		
		ZNSpace ..Namespace
		$$$THROWONERROR(tSC, $System.OBJ.ExportPackage(..Package, $ListToString(tempPath, "\") ))

	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	ZNSpace ns
	Quit tSC
}

/// create directory (recursively)
ClassMethod CreateDirectoryRecurse(Path As %String) As %Status
{
	Set tSC = $$$OK
	Try {
	    
	    Set folds = $ListFromString($$$FileNormalizeDirectory(Path),"/")
	    For k=1:1:$ListLength(folds) {
		    Set $List(tempPath, *+1) = $List(folds,k)
		    Set NormalizedPath  = $ListToString(tempPath,"/")

		    if $$$ISWINDOWS {
		        do $ZF(-1, "mkdir "_NormalizedPath)
		    }
		    else {
		        do $ZF(-1, "mkdir -p "_NormalizedPath)
		    }
	    }
	} Catch tException {
		Set:$$$ISOK(tSC) tSC = tException.AsStatus()
	}
	Quit tSC
}

}

