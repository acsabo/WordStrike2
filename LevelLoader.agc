#include "json_parser.agc"

Global description as String
Global category as String

Function PopulateString()
	
	nav1=LoadImage("Blue ships/bluegrayship (1).png") 
	fontImage=LoadImage("font1.png")

	Global dim fonts[26]
	for i = 0 to 25
		fonts[i] = CopyImage(fontImage, i*71, 0, 64, 64) 
	next i

	Global dim sprites[26,26]
	
	//FillWords
	word$= "ADRIANO"
	
	for i = 1 to Len(word$)
		j = i
		sprites[i,j] = CreateSprite(fonts[Asc(Mid(word$,i,1))-65])
	next i
	
	//Fill the gaps
	for i = 0 to 25
		for j = 0 to 25
			if sprites[i,j] = 0 
				sprites[i,j] = CreateSprite(fonts[Random(0,25)])
			endif
				
			SetSpritePosition(sprites[i,j], i * 28, j * 25)
			SetSpriteScale(sprites[i,j], 0.5, 0.5)
			
		next j
	next i	

EndFunction

Function LevelLoad()
	doc as Integer
	jsonCreateDocument(doc)
	jsonLoad(doc, "json\level.json")

	descriptionID = jsonGetObjectValue(doc, "", "description")
	description = jsonGetValueAsString(doc,descriptionID)

	themes=jsonGetArray(doc,"","themes") 
	themesCount=jsonGetValueCount(doc,themes)
	
	for il=0 to themesCount
		theme=jsonGetArrayEntry(doc,themes,il)  
		categoryID=jsonGetObjectValueById(doc,theme,"category")
		category=jsonGetValueAsString(doc,categoryID)
	next
	
	PopulateString()
EndFunction description


