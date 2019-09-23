
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

nav1=1

LoadImage(nav1, "Blue ships/bluegrayship (1).png")

obj_index = 1

for i = 1 to 13
	for j = 1 to 9
		CreateSprite(obj_index,nav1)
		SetSpriteScale(obj_index, 0.1, 0.1)
		//SetSpriteColorAlpha(obj_index, Random(50, 100))
		SetSpritePosition(obj_index, i*70, j*70)
		obj_index = obj_index+1
	next j
next i

do
	if GetPointerPressed() 
		sprite = GetSpriteHit( GetPointerX(), GetPointerY())
	endif
	
	Print(sprite)
		
	Print("WordStrike 2")
    Print( ScreenFPS() )
    Sync()
loop
