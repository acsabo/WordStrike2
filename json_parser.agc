
#constant	JSONTYPE_UNKNOWN	=-1
#constant	JSONTYPE_INTEGER	= 0
#constant	JSONTYPE_FLOAT		= 1
#constant	JSONTYPE_STRING		= 2
#constant	JSONTYPE_BOOL		= 3
#constant	JSONTYPE_NULL		= 4
#constant	JSONTYPE_OBJECT		= 5
#constant	JSONTYPE_ARRAY		= 6

#constant	JSON_ENDL = Chr(13) + Chr(10)

Type jsonValue
	str As String
	obj As jsonObject
	ary As jsonArray
	
	typ As Integer
EndType

Type jsonElement
	key as string
	id As Integer
EndType

Type jsonArray
	id As Integer[]
EndType

Type jsonObject
	object As jsonElement[]
EndType

type jsonDocument
	file As string
	code As String	
	ident As String
	
	memid As Integer
	memptr As Integer
	memsize As Integer
	//~ fid As Integer
	char As Integer[1]
	
	container As jsonValue[]
endtype

Global __json_g_whitespace As String
Global __json_g_errortext As String[]
Global __json_g_documents As jsonDocument[]

//	----------------------------------------------------------------------------
//	DOCUMENTED FUNCTIONS
//

// Document Load/Save/Create
// -----------------------------------------------------------------------------
//
Function jsonCreateDocument(docID As Integer)
	__json_g_whitespace = Chr(09) + Chr(32) + Chr(10) + Chr(13)

	If docId >= 0 And docId <= __json_g_documents.length
		If __json_g_documents[docID].container.length > 0 Then jsonClearDocument(docID)
	Else
		docID = -1
	EndIf

    if docId = -1
        __json_g_documents.length = __json_g_documents.length + 1
        docId = __json_g_documents.length
    endif
	
	If __json_g_documents[docID].container.length > 0 Then jsonClearDocument(docID)
	
	__json_g_documents[docID].code = ""
	__json_g_documents[docID].ident = ""
	//~ __json_g_documents[docID].fid = -1
	__json_g_documents[docID].memid = -1
	__json_g_documents[docID].memptr = 0
	dummy As jsonObject
	__json_create_new_object(docID, dummy, "root")
EndFunction docID

Function jsonLoad(docID As Integer, file As String)	
	If GetFileExists(file)
		docID = jsonCreateDocument(docID)
		
		__json_g_documents[docID].file = file
		
		//~ __json_g_documents[docID].fid = OpenToRead(file)
		__json_g_documents[docID].memid = CreateMemblockFromFile(file)
		__json_g_documents[docID].memptr = 0
		__json_g_documents[docID].memsize = GetMemblockSize(__json_g_documents[docID].memid)
		
		__json_read_next_byte(docID)
		__json_skip_whitespace(docID)
		__json_parse_object(docID, __json_g_documents[docID].container[0])
		//~ CloseFile(__json_g_documents[docID].fid)
		DeleteMemblock(__json_g_documents[docID].memid)
		//~ __json_g_documents[docID].fid = -1
		__json_g_documents[docID].memid = -1
		__json_g_documents[docID].memptr = -1
	EndIf
	
	__json_g_documents[docID].file = file
EndFunction docID

Function jsonCreateFromString(docID As Integer, code As String)	
	docID = jsonCreateDocument(docID)
	
	__json_g_documents[docID].file = ""
	
	__json_g_documents[docID].memid = CreateMemblock(Len(code)+1)
	__json_g_documents[docID].memptr = 0
	__json_g_documents[docID].memsize = GetMemblockSize(__json_g_documents[docID].memid)
	SetMemblockString(__json_g_documents[docID].memid, 0, code)

	__json_read_next_byte(docID)
	__json_skip_whitespace(docID)
	__json_parse_object(docID, __json_g_documents[docID].container[0])

	DeleteMemblock(__json_g_documents[docID].memid)
	__json_g_documents[docID].memid = -1
	__json_g_documents[docID].memptr = -1
EndFunction docID

Function jsonSave(docID As Integer)
	__json_g_documents[docID].code = ""
	
	__json_build_code(docID, __json_g_documents[docID].container[0])
	
	f As Integer
	f = OpenToWrite(__json_g_documents[docID].file, 0)
	If FileIsOpen(f) = 1
		WriteLine(f, __json_g_documents[docID].code)
		CloseFile(f)
	EndIf
EndFunction

Function jsonSaveAs(file As String, docID As Integer)
	__json_g_documents[docID].file = file
	jsonSave(docID)
EndFunction

Function jsonClearDocument(docID As Integer)
	While __json_g_documents[docID].container.length >= 0
		__json_clear_value(docID, __json_g_documents[docID].container[0])
		__json_g_documents[docID].container.remove(0)
	EndWhile
	
	__json_g_documents[docID].code = ""
	__json_g_documents[docID].ident = ""
	__json_g_documents[docID].char[0] = 0
	__json_g_documents[docID].char[1] = 0
	//~ __json_g_documents[docID].fid = -1
	__json_g_documents[docID].memid = -1
	__json_g_documents[docID].memptr = 0
	__json_g_documents[docID].file = ""
EndFunction

Function jsonValidateDocument(docID As Integer)
	orig As String
	orig = __json_g_documents[docID].file
	
	jsonSaveAs("validate_" + orig, docID)
	
	jsonClearDocument(docID)
	
	jsonCreateDocument(docID)

	jsonLoad(docID, "validate_" + orig)
	__json_g_documents[docID].file = orig
	
	DeleteFile("validate_" + orig)
EndFunction


// Values Set/Create
// -----------------------------------------------------------------------------
//
Function jsonCreateStringValue(value As String)
	out As jsonValue
	out.typ = JSONTYPE_STRING
	out.str = value
EndFunction out

Function jsonCreateFloatValue(value As Float)
	out As jsonValue
	out.typ = JSONTYPE_FLOAT
	//~ out.str = TruncateString(Str(value), "0")
	out.str = Str(value)
EndFunction out

Function jsonCreateIntegerValue(value As Integer)
	out As jsonValue
	out.typ = JSONTYPE_INTEGER
	out.str = Str(value)
EndFunction out

Function jsonCreateBooleanValue(value As Integer)
	out As jsonValue
	out.typ = JSONTYPE_BOOL
	
	v As String = "false"
	If value > 0 Then v = "true"
	out.str = v
EndFunction out

Function jsonCreateNullValue()
	out As jsonValue
	out.typ = JSONTYPE_NULL
	out.str = "null"
EndFunction out

Function jsonCreateObjectValue()
	out As jsonValue
	out.typ = JSONTYPE_OBJECT
	out.str = ""
EndFunction out

Function jsonCreateArrayValue()
	out As jsonValue
	out.typ = JSONTYPE_ARRAY
	out.str = ""
EndFunction out

Function jsonSetValue(docID As Integer, id As Integer, value Ref As jsonValue)
	If id < 0 Or id > __json_g_documents[docID].container.length Then ExitFunction
	If value.typ = JSONTYPE_UNKNOWN Then ExitFunction
	
	__json_g_documents[docID].container[id] = value
EndFunction

Function jsonGetValueAsString(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction ""
EndFunction __json_g_documents[docID].container[valueId].str

Function jsonGetValueAsInteger(docID As Integer, valueId As Integer, base As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction 0
	if __json_g_documents[docID].container[valueId].typ <> JSONTYPE_INTEGER Then ExitFunction 0
	
	out As Integer
	out = Val(__json_g_documents[docID].container[valueId].str, base)
EndFunction out

Function jsonGetValueAsFloat(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction 0.0
	if __json_g_documents[docID].container[valueId].typ <> JSONTYPE_FLOAT Then ExitFunction 0.0
	
	out As Float
	out = ValFloat(__json_g_documents[docID].container[valueId].str)
EndFunction out

Function jsonGetValueAsBoolean(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction 0
	if __json_g_documents[docID].container[valueId].typ <> JSONTYPE_BOOL Then ExitFunction 0

	if CompareString(__json_g_documents[docID].container[valueId].str, "true") Then ExitFunction 1
EndFunction 0

Function jsonGetValueAsNull(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction ""
	if __json_g_documents[docID].container[valueId].typ <> JSONTYPE_NULL Then ExitFunction ""
EndFunction "null"

Function jsonGetValueCount(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction -1
	
	If __json_g_documents[docID].container[valueId].typ = JSONTYPE_OBJECT Then ExitFunction __json_g_documents[docID].container[valueId].obj.object.length
	If __json_g_documents[docID].container[valueId].typ = JSONTYPE_ARRAY Then ExitFunction __json_g_documents[docID].container[valueId].ary.id.length
EndFunction -1

Function jsonGetValueType(docID As Integer, valueId As Integer)
	if valueId < 0 Or valueID > __json_g_documents[docID].container.length Then ExitFunction JSONTYPE_UNKNOWN
EndFunction __json_g_documents[docID].container[valueID].typ



// Object Get/Set/Remove Values
// -----------------------------------------------------------------------------
//
Function jsonGetObject(docID As Integer, path As String)
	id As Integer = -1
	id = __json_find_object(docID, path, __json_g_documents[docID].container[0].obj, 0)
	
	If id < 0 Then ExitFunction -1
	If __json_g_documents[docID].container[id].typ <> JSONTYPE_OBJECT Then ExitFunction -1
EndFunction id

Function jsonGetObjectEntry(docID As Integer, objId As Integer, key As String)
	If objId < 0 Or objID > __json_g_documents[docID].container.length Then ExitFunction -1

	id As Integer = -1
	id = __json_find_value_by_key(docID, __json_g_documents[docID].container[objId].obj, key, 0)
EndFunction id

Function jsonGetObjectEntryAt(docID As Integer, objId As Integer, index As Integer)
	If objId < 0 Or objID > __json_g_documents[docID].container.length Then ExitFunction -1
	If __json_g_documents[docID].container[objId].typ <> JSONTYPE_OBJECT Then ExitFunction -1
	If index > __json_g_documents[docID].container[objId].obj.object.length Or index < 0 Then ExitFunction -1
EndFunction __json_g_documents[docID].container[objId].obj.object[index].id

Function jsonGetObjectNameAt(docID As Integer, objId As Integer, index As Integer)
	If objId < 0 Or objID > __json_g_documents[docID].container.length Then ExitFunction ""
	If __json_g_documents[docID].container[objId].typ <> JSONTYPE_OBJECT Then ExitFunction ""
	If index > __json_g_documents[docID].container[objId].obj.object.length Or index < 0 Then ExitFunction ""
EndFunction __json_g_documents[docID].container[objId].obj.object[index].key

Function jsonSetObjectValue(docID As Integer, path As String, key As String, value Ref As jsonValue, create As Integer)
	id as Integer
	oid As Integer
	
	oid = __json_find_object(docID, path, __json_g_documents[docID].container[0].obj, create)
	If __json_g_documents[docID].container[oid].typ <> JSONTYPE_OBJECT Then ExitFunction -1
	
	id = __json_find_value_by_key(docID, __json_g_documents[docID].container[oid].obj, key, create)
	If id < 0 Then ExitFunction -1
	
	jsonSetValue(docID, id, value)
EndFunction id

Function jsonRemoveObjectContent(docID As Integer, path As String)
	objId As Integer
	objId = jsonGetObject(docID, path)

	jsonRemoveObjectContentById(docID, objId)
EndFunction

Function jsonRemoveObjectContentById(docID As Integer, objId As Integer)
	If objId < 0 Or objId > __json_g_documents[docID].container.length Then ExitFunction
	If __json_g_documents[docID].container[objId].typ <> JSONTYPE_OBJECT Then ExitFunction

	While __json_g_documents[docID].container[objId].obj.object.length >= 0
		jsonRemoveObjectEntryAt(docID, objId, 0)
	EndWhile
EndFunction

Function jsonRemoveObjectEntry(docID As Integer, path As String, key As String)
	objId As Integer
	objId = jsonGetObject(docID, path)
	
	jsonRemoveObjectEntryById(docID, objId, key)
EndFunction

Function jsonRemoveObjectEntryById(docID As Integer, objId As Integer, key As String)
	If objId < 0 Or objId > __json_g_documents[docID].container.length Then ExitFunction
	If __json_g_documents[docID].container[objId].typ <> JSONTYPE_OBJECT Then ExitFunction

	id As Integer
	id = jsonGetObjectEntry(docID, objId, key)
	if id < 0 Then ExitFunction
	
	__json_find_value_by_key(docID, __json_g_documents[docID].container[objId].obj, key, -1)
EndFunction

Function jsonRemoveObjectEntryAt(docID As Integer, objId As Integer, index As Integer)
	If objId < 0 Or objId > __json_g_documents[docID].container.length Then ExitFunction
	If __json_g_documents[docID].container[objId].typ <> JSONTYPE_OBJECT Then ExitFunction
	
	id As Integer
	id = jsonGetObjectEntryAt(docID, objId, index)
	if id < 0 Then ExitFunction

	__json_clear_value(docID, __json_g_documents[docID].container[id])
	__json_g_documents[docID].container[objId].obj.object.remove(index)
EndFunction

Function jsonGetObjectValue(docID As Integer, path As String, key As String)
	id as Integer
	id = jsonGetObjectEntry(docID, jsonGetObject(docID, path), key)
	
	If id < 0 Then ExitFunction -1
	If __json_g_documents[docID].container[id].typ = JSONTYPE_OBJECT Or __json_g_documents[docID].container[id].typ = JSONTYPE_ARRAY Then ExitFunction -1
EndFunction id

Function jsonSetObjectValueById(docID As Integer, objId As Integer, key As String, value As jsonValue, create As Integer)
	If objId < 0 Or objId > __json_g_documents[docID].container.length Then ExitFunction -1
	If __json_g_documents[docID].container[objid].typ <> JSONTYPE_OBJECT Then ExitFunction -1
	If value.typ = JSONTYPE_UNKNOWN Then ExitFunction -1
	
	id as Integer
	id = __json_find_value_by_key(docID, __json_g_documents[docID].container[objId].obj, key, create)	
	if id < 0 Then ExitFunction -1
	
	jsonSetValue(docID, id, value)
EndFunction id

Function jsonGetObjectValueById(docID As Integer, objId As Integer, key As String)
	out As jsonValue
	out.typ = JSONTYPE_UNKNOWN
	
	If objId < 0 Or objId > __json_g_documents[docID].container.length Then ExitFunction -1
	If __json_g_documents[docID].container[objid].typ <> JSONTYPE_OBJECT Then ExitFunction -1
	
	id as Integer
	id = jsonGetObjectEntry(docID, objId, key)
EndFunction id



// Array Get/Set Values
// -----------------------------------------------------------------------------
//
Function jsonGetArray(docID As Integer, path As String, name As String)
	id As Integer = -1
	id = __json_find_object(docID, path, __json_g_documents[docID].container[0].obj, 0)
	
	If id < 0 Then ExitFunction -1
	If __json_g_documents[docID].container[id].typ <> JSONTYPE_OBJECT Then ExitFunction -1
	
	id = __json_find_value_by_key(docID, __json_g_documents[docID].container[id].obj, name, 0)
	If id < 0 Then ExitFunction -1

	If __json_g_documents[docID].container[id].typ = JSONTYPE_UNKNOWN Then __json_g_documents[docID].container[id].typ = JSONTYPE_ARRAY
	If __json_g_documents[docID].container[id].typ <> JSONTYPE_ARRAY Then ExitFunction -1
EndFunction id

Function jsonGetArrayEntry(docID As Integer, aryId As Integer, index As Integer)
	If aryId < 0 Or aryId > __json_g_documents[docID].container.length Then ExitFunction -1
	If __json_g_documents[docID].container[aryId].typ <> JSONTYPE_ARRAY Then ExitFunction -1
	If index < 0 Then ExitFunction -1

	id As Integer = -1
	id = __json_find_value_by_index(docID, __json_g_documents[docID].container[aryId].ary, index, 0)
EndFunction id

Function jsonSetArrayValue(docID As Integer, path As String, name As String, index As Integer, value As jsonValue, create As Integer)
	aid As Integer
	aid = __json_find_object(docID, path, __json_g_documents[docID].container[0].obj, create)	
	
	If aid < 0 Or aid > __json_g_documents[docID].container.length Then ExitFunction -1
	If __json_g_documents[docID].container[aid].typ <> JSONTYPE_OBJECT Then ExitFunction -1

	aid = __json_find_value_by_key(docID, __json_g_documents[docID].container[aid].obj, name, create)
	If __json_g_documents[docID].container[aid].typ = JSONTYPE_UNKNOWN Then __json_g_documents[docID].container[aid].typ = JSONTYPE_ARRAY
	If __json_g_documents[docID].container[aid].typ <> JSONTYPE_ARRAY Then ExitFunction -1
	
	id as Integer
	id = __json_find_value_by_index(docID, __json_g_documents[docID].container[aid].ary, index, create)
	if id < 0 Then ExitFunction -1
	
	jsonSetValue(docID, id, value)
EndFunction id

Function jsonSetArrayValueById(docID As Integer, aryId As Integer, index As Integer, value As jsonValue, create As Integer)
	If aryId < 0 Or aryId > __json_g_documents[docID].container.length Then ExitFunction -1
	
	id as Integer
	id =  __json_find_value_by_index(docID, __json_g_documents[docID].container[aryId].ary, index, create)
	if id < 0 Then ExitFunction -1
	
	jsonSetValue(docID, id, value)
EndFunction id

Function jsonRemoveArrayContent(docID As Integer, path As String, name As String)
	aryId As Integer
	aryId = jsonGetObjectEntry(docID, jsonGetObject(docID, path), name)
	
	If aryId < 0 Or aryId > __json_g_documents[docID].container.length Then ExitFunction
	If __json_g_documents[docID].container[aryId].typ <> JSONTYPE_ARRAY Then ExitFunction

	While __json_g_documents[docID].container[aryId].ary.id.length >= 0
		jsonRemoveArrayEntryById(docID, aryId, 0)
	EndWhile
EndFunction

Function jsonRemoveArrayEntry(docID As Integer, path As String, name As String, index As Integer)
	aryId As Integer
	aryId = jsonGetArray(docID, path, name)
	If aryId < 0 Then ExitFunction
	
	jsonRemoveArrayEntryById(docID, aryId, index)
EndFunction

Function jsonRemoveArrayEntryById(docID As Integer, aryId As Integer, index As Integer)
	If aryId < 0 Or aryId > __json_g_documents[docID].container.length Then ExitFunction
	If __json_g_documents[docID].container[aryId].typ <> JSONTYPE_ARRAY Then ExitFunction
	If index < 0 Or index > __json_g_documents[docID].container[aryId].ary.id.length Then ExitFunction
	
	__json_find_value_by_index(docID, __json_g_documents[docID].container[aryId].ary, index, -1)
EndFunction

// Error handling
// -----------------------------------------------------------------------------
//
Function jsonHasErrors(docID As Integer)
EndFunction __json_g_errortext.length

Function jsonGetErrors(docID As Integer)
EndFunction __json_g_errortext

Function jsonClearErrors(docID As Integer)
	__json_g_errortext.length = -1
EndFunction





//	----------------------------------------------------------------------------
//	INTERN FUNCTIONS
//
Function __json_clear_value(docID As Integer, value Ref As jsonValue)
	If value.typ = JSONTYPE_UNKNOWN Then ExitFunction
		
	If value.ary.id.length >= 0
		While value.ary.id.length >= 0
			__json_clear_value(docID, __json_g_documents[docID].container[value.ary.id[0]])
			value.ary.id.remove(0)
		EndWhile
	EndIf
	
	If value.obj.object.length >= 0
		While value.obj.object.length >= 0
			__json_clear_value(docID, __json_g_documents[docID].container[value.obj.object[0].id])
			value.obj.object.remove(0)
		EndWhile
	EndIf	

	value.typ = JSONTYPE_UNKNOWN
	value.str = ""
EndFunction

Function __json_find_object(docID As Integer, path As String, obj0 Ref As jsonObject, create As Integer)
	If Len(path) = 0 Then ExitFunction 0
	
	count As Integer
	count = obj0.object.length
	
	token As String
	token = GetStringToken(path, "~", 0)
	path = Right(path, Len(path) - (Len(token)))

	id As Integer = -1
	i As Integer
	For i=0 To count
		If CompareString(token, obj0.object[i].key) = 1
			If __json_g_documents[docID].container[obj0.object[i].id].typ = JSONTYPE_OBJECT
				id = obj0.object[i].id
				If Len(path) > 1
					id = __json_find_object(docID, Right(path, Len(path)-1), __json_g_documents[docID].container[id].obj, create)
				EndIf				
			EndIf
		EndIf
	Next
	
	If id = -1 And create = 1 And Len(token) > 0
		id = __json_create_new_object(docID, obj0, token)
		If Len(path) > 1
			id = __json_find_object(docID, Right(path, Len(path)-1), __json_g_documents[docID].container[id].obj, create)
		EndIf				
	EndIf
EndFunction id

Function __json_create_new_object(docID As Integer, parentObj Ref As jsonObject, key As String)
	value As jsonValue
	value.typ = JSONTYPE_OBJECT
	__json_g_documents[docID].container.insert(value)
	
	id As Integer
	id = __json_g_documents[docID].container.length
	
	If CompareString(key, "root") = 1 Then ExitFunction id
		
	element As jsonElement
	element.id = id
	element.key = key
	parentObj.object.insert(element)	
EndFunction id

Function __json_create_new_value(docID As Integer)
	value As jsonValue
	value.typ = JSONTYPE_NULL
	__json_g_documents[docID].container.insert(value)
	
	id As Integer
	id = __json_g_documents[docID].container.length
EndFunction id

Function __json_find_value_by_key(docID As Integer, obj Ref As jsonObject, key As String, create As Integer)
	count As Integer
	count = obj.object.length
	
	If count >= 0
		i As Integer
		For i=0 To count
			If CompareString(obj.object[i].key, key)
				If create = -1
					__json_clear_value(docID, __json_g_documents[docID].container[obj.object[i].id])
					obj.object.remove(i)
					ExitFunction -1
				EndIf
				ExitFunction obj.object[i].id
			EndIf
		Next
	EndIf

	id As Integer = -1
	If create = 1
		v As jsonValue
		v.typ = JSONTYPE_UNKNOWN
		__json_g_documents[docID].container.insert(v)
		
		element As jsonElement
		element.key = key
		element.id = __json_g_documents[docID].container.length
		
		obj.object.insert(element)
		id = element.id
	EndIf
EndFunction id

Function __json_find_value_by_index(docID As Integer, ary Ref As jsonArray, index As Integer, create As Integer)
	count As Integer
	count = ary.id.length
	
	If index > count And create = 1
		While index > count
			ary.id.insert(__json_create_new_value(docID))
			Inc count
		EndWhile
	ElseIf index > count || index < 0
		ExitFunction -1
	EndIf
	
	If create = -1
		__json_clear_value(docID, __json_g_documents[docID].container[ary.id[index]])
		ary.id.remove(index)
		ExitFunction -1
	EndIf
EndFunction ary.id[index]

Function __json_build_code(docID As Integer, parent Ref As jsonValue)
	Select parent.typ
		Case	JSONTYPE_ARRAY:
			__json_build_array_code(docID, parent.ary)
		EndCase
		
		Case	JSONTYPE_BOOL:
			__json_g_documents[docID].code = __json_g_documents[docID].code + parent.str
		EndCase
		
		Case	JSONTYPE_FLOAT:
			__json_g_documents[docID].code = __json_g_documents[docID].code + __crop_float_string(parent.str)
		EndCase
		
		Case	JSONTYPE_INTEGER:
			__json_g_documents[docID].code = __json_g_documents[docID].code + parent.str
		EndCase
		
		Case	JSONTYPE_NULL:
			__json_g_documents[docID].code = __json_g_documents[docID].code + "null"
		EndCase
		
		Case	JSONTYPE_OBJECT:
			__json_build_object_code(docID, parent.obj)
		EndCase
		
		Case	JSONTYPE_STRING:
			__json_g_documents[docID].code = __json_g_documents[docID].code + Chr(34) + parent.str + Chr(34)
		EndCase
		
		Case	JSONTYPE_UNKNOWN:
		EndCase
	EndSelect
EndFunction

Function __crop_float_string(value As String)
	//~ pos As Integer
	//~ pos = FindString(value, ".", 0, -1)
	//~ If pos = 0 Then ExitFunction value
	//~ 
	//~ Inc pos, 2
	//~ pos = FindString(value, "0", 0, pos)
	//~ If pos = 0 Then ExitFunction value
	//~ 
	//~ value = Left(value, pos-1)
	
	count As Integer
	count = Len(value)
	While Mid(value, count, 1) = "0"
		Dec count, 1
	EndWHile
	
	If Mid(value, count, 1) = "." Then Inc count, 1
	
	value = Left(value, count)
EndFunction value


Function __json_build_object_code(docID As Integer, obj Ref as jsonObject)
	__json_g_documents[docID].ident = __json_g_documents[docID].ident + "    "

	hasNested As Integer
	hasNested = __json_object_has_nested(docID, obj)
	
	nextVal As String
	nextVal = " "
	If hasNested = 1 Then nextVal = JSON_ENDL + __json_g_documents[docID].ident

	__json_g_documents[docID].code = __json_g_documents[docID].code + "{" + nextVal
	
	count As Integer
	count = obj.object.length
	i As Integer
	For i=0 To count
		__json_g_documents[docID].code = __json_g_documents[docID].code + Chr(34) + obj.object[i].key + Chr(34) + " : "
		__json_build_code(docID, __json_g_documents[docID].container[obj.object[i].id])
		
		if i <> count Then __json_g_documents[docID].code = __json_g_documents[docID].code + "," Else nextVal = Left(nextVal, Len(NextVal)-4)
		__json_g_documents[docID].code = __json_g_documents[docID].code + nextVal
	Next
	
	__json_g_documents[docID].ident = Left(__json_g_documents[docID].ident, Len(__json_g_documents[docID].ident) - 4)
	__json_g_documents[docID].code = __json_g_documents[docID].code + "}"
EndFunction

Function __json_build_array_code(docID As Integer, ary Ref as jsonArray)
	__json_g_documents[docID].ident = __json_g_documents[docID].ident + "  "

	hasNested As Integer
	hasNested = __json_array_has_nested(docID, ary)
	
	nextVal As String
	nextVal = " "
	If hasNested = 1 Then nextVal = JSON_ENDL + __json_g_documents[docID].ident

	__json_g_documents[docID].code = __json_g_documents[docID].code + "[" + nextVal
	
	count As Integer
	count = ary.id.length
	i As Integer
	For i=0 To count
		__json_build_code(docID, __json_g_documents[docID].container[ary.id[i]])
		
		if i <> count Then __json_g_documents[docID].code = __json_g_documents[docID].code + "," Else nextVal = Left(nextVal, Len(NextVal)-2)
		__json_g_documents[docID].code = __json_g_documents[docID].code + nextVal
	Next
	
	__json_g_documents[docID].ident = Left(__json_g_documents[docID].ident, Len(__json_g_documents[docID].ident) - 2)
	__json_g_documents[docID].code = __json_g_documents[docID].code + "]"
EndFunction

Function __json_object_has_nested(docID As Integer, obj Ref As jsonObject)
	count As Integer = 0
	
	count = obj.object.length
	If count > -1
		i As Integer
		For i=0 To count
			id As Integer
			id = obj.object[i].id
			If __json_g_documents[docID].container[id].typ = JSONTYPE_ARRAY Or __json_g_documents[docID].container[id].typ = JSONTYPE_OBJECT Then ExitFunction 1
			//~ If __json_g_documents[docID].container[id].typ = JSONTYPE_STRING And count > 8 Then ExitFunction 1
			If count > 8 Then ExitFunction 1
		Next
	EndIf
EndFunction 0

Function __json_array_has_nested(docID As Integer, ary Ref As jsonArray)
	out As Integer = 0
	count As Integer = 0
	
	count = ary.id.length
	If count > -1
		i As Integer
		For i=0 To count
			id As Integer
			id = ary.id[i]
			if __json_g_documents[docID].container[id].typ = JSONTYPE_ARRAY Or __json_g_documents[docID].container[id].typ = JSONTYPE_OBJECT Then out = 1
		Next
	Endif
EndFunction out

Function __json_parse_object(docID As Integer, parent Ref As jsonValue)
	__json_skip_whitespace(docID)
	
	If __json_g_documents[docID].char[0] = 0x7b // {
		__json_read_next_byte(docID)
		__json_skip_whitespace(docID)
		
		parent.typ = JSONTYPE_OBJECT
		
		While __json_g_documents[docID].char[0] <> 0x7d	// }
			element As jsonElement
			
			element.key = __json_parse_key(docID)
			element.id = __json_parse_value(docID)
			
			parent.obj.object.insert(element)
			__json_skip_whitespace(docID)
			
			if __json_g_documents[docID].char[0] = 0x2c Then __json_read_next_byte(docID)
		EndWhile
		
		__json_read_next_byte(docID)
	EndIf
EndFunction

Function __json_parse_array(docID As Integer, parent Ref As jsonValue)
	__json_skip_whitespace(docID)
	
	If __json_g_documents[docID].char[0] = 0x5b	// [
		__json_read_next_byte(docID)
		__json_skip_whitespace(docID)
		
		parent.typ = JSONTYPE_ARRAY
		
		While __json_g_documents[docID].char[0] <> 0x5d	// ]
			id As Integer
			id = __json_parse_value(docID)
			
			parent.ary.id.insert(id)
			__json_skip_whitespace(docID)
			
			if __json_g_documents[docID].char[0] = 0x2c Then __json_read_next_byte(docID)
		EndWhile
		
		__json_read_next_byte(docID)
	EndIf
EndFunction

Function __json_parse_string(docID As Integer, parent Ref As jsonValue)
	__json_skip_whitespace(docID)

	If __json_g_documents[docID].char[0] = 0x22	// "
		parent.typ = JSONTYPE_STRING
		
		parent.str = __json_parse_common_string(docID)
	EndIf
EndFunction

Function __json_parse_boolean(docID As Integer, parent Ref As jsonValue)
	parent.typ = JSONTYPE_UNKNOWN
	
	parent.str = ""
	While __json_is_alpha(__json_g_documents[docID].char[0]) = 1
		parent.str = parent.str + Chr(__json_g_documents[docID].char[0])
		__json_read_next_byte(docID)
	EndWhile

	If CompareString(parent.str, "true", 1, -1) = 1 Or CompareString(parent.str, "false", 1, -1) = 1
		parent.typ = JSONTYPE_BOOL
		parent.str = Lower(parent.str)
	Else
		parent.str = ""
		__json_g_errortext.insert("Parse error: Can't recognize 'boolean'.")
	EndIf
EndFunction

Function __json_parse_null(docID As Integer, parent Ref As jsonValue)
	parent.typ = JSONTYPE_UNKNOWN
	
	parent.str = ""
	While __json_is_alpha(__json_g_documents[docID].char[0]) = 1
		parent.str = parent.str + Chr(__json_g_documents[docID].char[0])
		__json_read_next_byte(docID)
	EndWhile

	If CompareString(parent.str, "null", 1, -1) = 1
		parent.typ = JSONTYPE_NULL
		parent.str = Lower(parent.str)
	Else
		parent.str = ""
		__json_g_errortext.insert("Parse error: Can't recognize 'nil'.")
	EndIf
EndFunction

Function __json_parse_number(docID As Integer, parent Ref As jsonValue)
	parent.typ = JSONTYPE_INTEGER
	
	parent.str = ""
	While __json_is_realdigit(__json_g_documents[docID].char[0]) = 1
		parent.str = parent.str + Chr(__json_g_documents[docID].char[0])
		If __json_g_documents[docID].char[0] = 0x2e Then parent.typ = JSONTYPE_FLOAT
		
		__json_read_next_byte(docID)
	EndWhile
EndFunction

Function __json_skip_whitespace(docID As Integer)
	While __json_is_whitespace(__json_g_documents[docID].char[0]) = 1
		__json_read_next_byte(docID)
	EndWhile
EndFunction

Function __json_is_realdigit(char As Integer)
	out As Integer = 0
	if (char >= 0x30 And char <= 0x39) Or char = 0x2e Or char = 0x45 Or char = 0x65 Or char = 0x2d Or char = 0x2b Then out = 1
EndFunction out

Function __json_is_alpha(char As Integer)
	out As Integer = 0
	if (char >= 0x41 And char <= 0x5a) Or (char >= 0x61 And char <= 0x7a) Then out = 1
EndFunction out

Function __json_is_whitespace(char As Integer)
	out As Integer = 0
	if char = 32 Or char = 9 Or char = 10 Or char = 13 Then out = 1
EndFunction out

Function __json_is_string_end(char0 As Integer, char1 As Integer)
	out As Integer = 0
	if char0 = 0x22 And char1 <> 0x5c Then out = 1
EndFunction out

Function __json_read_next_byte(docID As Integer)
	If __json_g_documents[docID].memptr < __json_g_documents[docID].memsize
		__json_g_documents[docID].char[1] = __json_g_documents[docID].char[0]
		//~ __json_g_documents[docID].char[0] = ReadByte(__json_g_documents[docID].fid)
		__json_g_documents[docID].char[0] = GetMemblockByte(__json_g_documents[docID].memid, __json_g_documents[docID].memptr)
		Inc __json_g_documents[docID].memptr
	EndIf	
EndFunction

Function __json_parse_key(docID As Integer)
	key As String
	key = __json_parse_common_string(docID)

	__json_skip_whitespace(docID)

	If __json_g_documents[docID].char[0] <> Asc(":")
		__json_g_errortext.insert("Parse error: Can't recognize 'key'.")
	EndIf
	
	__json_read_next_byte(docID)
EndFunction key

Function __json_parse_common_string(docID As Integer)
	out As String
	__json_skip_whitespace(docID)

	If __json_g_documents[docID].char[0] = 0x22
		__json_read_next_byte(docID)
		//~ While __json_g_documents[docID].char[0] <> 34 And __json_g_documents[docID].char[1] <> 92
		While __json_is_string_end(__json_g_documents[docID].char[0], __json_g_documents[docID].char[1]) = 0
			out = out + Chr(__json_g_documents[docID].char[0])
			__json_read_next_byte(docID)
		EndWhile
	Else
		__json_g_errortext.insert("Parse error: Is not a string.")
	EndIf
	
	__json_read_next_byte(docID)
EndFunction out

Function __json_parse_value(docID As Integer)
	out As jsonValue
	__json_skip_whitespace(docID)
	
	if __json_g_documents[docID].char[0] >= 0x61 And __json_g_documents[docID].char[0] <= 0x7a Then Dec __json_g_documents[docID].char[0], 0x20

	Select __json_g_documents[docID].char[0]
		Case 0x7b:		// { (Object)
			__json_parse_object(docID, out)
		EndCase
		
		Case 0x5b:		// [ (Array)
			__json_parse_array(docID, out)
		EndCase
		
		Case 0x22:		// " (String)
			__json_parse_string(docID, out)
		EndCase
		
		Case Default:
			If __json_g_documents[docID].char[0] = 0x54 Or __json_g_documents[docID].char[0] = 0x46			// True / False
				__json_parse_Boolean(docID, out)
			ElseIf __json_g_documents[docID].char[0] = 0x4e							// Null
				__json_parse_Null(docID, out)
			//~ ElseIf __json_g_documents[docID].char[0] >= 0x30 And __json_g_documents[docID].char[0] <= 0x39	// Number
			ElseIf __json_is_realdigit(__json_g_documents[docID].char[0]) = 1	// Number
				__json_parse_number(docID, out)
			Else
				__json_g_errortext.insert("Parse error: Can't recognize 'value'.")
			EndIf
		EndCase
	EndSelect

	num As Integer
	num = __json_g_documents[docID].container.length + 1
	__json_g_documents[docID].container.insert(out)
EndFunction num
