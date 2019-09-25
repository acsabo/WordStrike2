#include "LevelLoader.agc"

//description as String
//category as String
//description = LoadLevel() 
LevelLoad() 

// Project: WordStrike2 
// Created: 2019-09-22

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle( "WordStrike2" )
SetWindowSize( 1024, 768, 0 )
SetWindowAllowResize( 1 ) // allow the user to resize the window

// set display properties
SetVirtualResolution( 1024, 768 ) // doesn't have to match the window
SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
SetSyncRate( 30, 0 ) // 30fps instead of 60 to save battery
SetScissor( 0,0,0,0 ) // use the maximum available screen space, no black borders
UseNewDefaultFonts( 1 ) // since version 2.0.22 we can use nicer default fonts

/*
nav1=LoadImage("Blue ships/bluegrayship (1).png") 
fontImage=LoadImage("font1.png")

dim fonts[26]
for i = 0 to 25
	fonts[i] = CopyImage(fontImage, i*71, 0, 64, 64) 
next i

dim sprites[26,26]
for i = 0 to 25
	for j = 0 to 25
		sprites[i,j] = CreateSprite(fonts[i])
		SetSpritePosition(sprites[i,j], i * 28, j * 25)
		SetSpriteScale(sprites[i,j], 0.5, 0.5)
	next j
next i

*/

/*

for i = 1 to 13
	for j = 1 to 9
		obj_index = CreateSprite(nav1)
		SetSpriteScale(obj_index, 0.1, 0.1)
		//SetSpriteColorAlpha(obj_index, Random(50, 100))
		SetSpritePosition(obj_index, i*70, j*70)
	next j
next i
*/


//background color
SetClearColor(0x0, 0x70, 0x70)

do
	if GetPointerPressed() 
		sprite = GetSpriteHit( GetPointerX(), GetPointerY())
	endif
	
	/*
    Print(description)
    Print(category)
	Print(sprite)
		
	Print("WordStrike 2")
	Print(Asc(Mid("ADRIANO",1,1)))
	
    Print( ScreenFPS() )
    */
    Sync()
loop
