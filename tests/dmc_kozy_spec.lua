--====================================================================--
-- tests/dmc_kozy_spec.lua
--
-- Unit tests for dmc-kozy, using Luna Test.
-- Run with tests/run_unit.sh
--
-- Solar2D's display and native are stand-ins here: their objects
-- record what their color methods are called with
--====================================================================--


module(..., package.seeall)



--====================================================================--
--== Setup


local MODULE = 'dmc_corona.dmc_kozy'

local cfgFile = 'dmc_corona.cfg'

-- stand-ins for the Solar2D globals the module uses
package.preload.json = function() return require 'dkjson' end

_G.system = {
	ResourceDirectory=newproxy(),
	pathForFile=function( name ) return './'..cfgFile end,
}

-- newObject()
-- a display object whose methods record their arguments in calls
--
local function newObject( ... )
	local o = { args={ ... }, calls={}, anchorX=0.5, anchorY=0.5 }
	for _, name in ipairs{ 'setFillColor', 'setStrokeColor', 'setTextColor' } do
		o[ name ] = function( self, ... )
			o.calls[ #o.calls+1 ] = { name=name, self=self, n=select( '#', ... ), ... }
		end
	end
	return o
end

local SOLAR2D_CENTER = newproxy()

_G.display = {
	contentWidth=320,
	CenterReferencePoint=SOLAR2D_CENTER,
	TopLeftReferencePoint=newproxy(),
	newImage=function( name )
		if name == 'missing.png' then return nil end
		return newObject( name )
	end,
}
for _, name in ipairs{ 'newCircle', 'newContainer', 'newGroup',
	'newImageRect', 'newLine', 'newPolygon', 'newRect', 'newRoundedRect',
	'newSprite', 'newText' } do
	display[ name ] = newObject
end
display.newImageRect = display.newImage

_G.native = {
	systemFont='system',
	newTextBox=newObject,
	newTextField=newObject,
	newWebView=newObject,
}

-- load()
-- a fresh copy of the module, with this [DMC_KOZY] config;
-- nil for no config at all: the boot loader reads cfgFile
--
local function load( config )
	package.loaded[ MODULE ] = nil
	package.loaded[ 'dmc_corona_boot' ] = nil
	_G.__dmc_corona = nil
	if config then
		_G.__dmc_corona = { dmc_corona={}, dmc_kozy=config }
	end
	return require( MODULE )
end

-- lastCall()
-- the last color call on o, as { name, values... }
--
local function lastCall( o )
	return o.calls[ #o.calls ]
end

-- assert_color()
-- the values, to 3 places
--
local function assert_color( expected, call )
	assert_equal( #expected, call.n )
	for i, v in ipairs( expected ) do
		assert_true( math.abs( v - call[i] ) < 0.001,
			'value '..i..': '..tostring( call[i] )..', expected '..v )
	end
end

local function assert_error_match( pattern, f )
	local ok, err = pcall( f )
	assert_false( ok )
	assert_match( pattern, err )
end



--====================================================================--
--== Tests


function test_module()
	local Kozy = load( {} )
	assert_equal( '1.1.0', Kozy.VERSION )
	local d, n = Kozy()
	assert_equal( 'DMC Kozy Display', d.NAME )
	assert_equal( 'DMC Kozy Native', n.NAME )
	assert_equal( d, Kozy.display )
	assert_equal( n, Kozy.native )
	-- the rest falls through to Solar2D's
	assert_equal( 320, d.contentWidth )
	assert_equal( 'system', n.systemFont )
end

function test_no_globals()
	local d = load( {} )()
	local o = d.newRect( 0, 0, 10, 10 )
	o:setAnchor( 0 )
	o:setFillColor{ type='gradient', color1={ 0, 0, 0 }, color2={ 1, 1, 1 } }
	for _, name in ipairs{ '_extend', 'createClosure', 't', 'NAMED_COLORS' } do
		assert_nil( rawget( _G, name ), name )
	end
	assert_equal( display, _G.display )
end

function test_colors()
	local d = load( {} )()
	local o = d.newRect()
	o:setFillColor( 255, 0, 51 )
	assert_color( { 1, 0, 0.2, 1 }, lastCall( o ) )
	assert_equal( o, lastCall( o ).self )
	o:setFillColor( 255, 0, 51, 0.5 )
	assert_color( { 1, 0, 0.2, 0.5 }, lastCall( o ) )
	o:setFillColor( 51 )
	assert_color( { 0.2, 0.2, 0.2, 1 }, lastCall( o ) )
	o:setStrokeColor( '#FF3300' )
	assert_equal( 'setStrokeColor', lastCall( o ).name )
	assert_color( { 1, 0.2, 0 }, lastCall( o ) )
end

-- the alpha was dropped: always 1
function test_gray_with_alpha()
	local d = load( {} )()
	local o = d.newCircle()
	o:setFillColor( 51, 0.25 )
	assert_color( { 0.2, 0.2, 0.2, 0.25 }, lastCall( o ) )
end

function test_alpha_0_255()
	local d = load( { activate_zeroone_alpha=false } )()
	local o = d.newRect()
	o:setFillColor( 51, 51 )
	assert_color( { 0.2, 0.2, 0.2, 0.2 }, lastCall( o ) )
	o:setFillColor( 0, 0, 0, 102 )
	assert_color( { 0, 0, 0, 0.4 }, lastCall( o ) )
end

-- the table was translated in place, so its second use was near black
function test_gradient_copied()
	local d = load( {} )()
	local o = d.newRect()
	local g = { type='gradient', color1={ 255, 0, 0 }, color2={ 0, 0, 255, 0.5 }, direction='right' }
	o:setFillColor( g )
	o:setFillColor( g )
	local paint = lastCall( o )[1]
	assert_equal( 'right', paint.direction )
	assert_color( { 1, 0, 0, 1 }, { n=4, unpack( paint.color1 ) } )
	assert_color( { 0, 0, 1, 0.5 }, { n=4, unpack( paint.color2 ) } )
	assert_equal( 255, g.color1[1] )
end

function test_other_paints()
	local d = load( {} )()
	local o = d.newRect()
	local paint = { type='image', filename='a.png' }
	o:setFillColor( paint )
	assert_equal( paint, lastCall( o )[1] )
end

-- a name printed "ERROR dmc_kolor" and gave white
function test_bad_colors()
	local d = load( {} )()
	local o = d.newRect()
	assert_error_match( "dmc_kozy: invalid color 'red'.*dmc%-kolor", function() o:setFillColor( 'red' ) end )
	assert_error_match( "invalid color '#FFF'", function() o:setFillColor( '#FFF' ) end )
	assert_error_match( 'invalid color type nil', function() o:setFillColor() end )
	assert_error_match( 'argument 2 is a string', function() o:setStrokeColor( 1, '2', 3 ) end )
	assert_error_match( '5 numbers', function() o:setFillColor( 1, 2, 3, 4, 5 ) end )
	assert_error_match( 'gradient color2', function()
		o:setFillColor{ type='gradient', color1={ 1, 2, 3 } }
	end )
	assert_equal( 0, #o.calls )
end

-- the error is reported at the caller's line
function test_error_level()
	local d = load( {} )()
	local o = d.newRect()
	local ok, err = pcall( function() o:setFillColor( 'red' ) end )
	assert_match( '^[^:]*dmc_kozy_spec.lua:%d+: dmc_kozy', err )
end

function test_set_anchor()
	local d = load( {} )()
	local o = d.newGroup()
	o:setAnchor( 0, 1 )
	assert_equal( 0, o.anchorX ) ; assert_equal( 1, o.anchorY )
	o:setAnchor{ 1, 0.5 }
	assert_equal( 1, o.anchorX ) ; assert_equal( 0.5, o.anchorY )
	-- a missing value keeps the current one
	o:setAnchor( 0.25 )
	assert_equal( 0.25, o.anchorX ) ; assert_equal( 0.5, o.anchorY )
	o:setAnchor( nil, 0 )
	assert_equal( 0.25, o.anchorX ) ; assert_equal( 0, o.anchorY )
	assert_error_match( 'setAnchor%(%) takes numbers', function() o:setAnchor( 'top' ) end )
end

function test_set_reference_point()
	local d = load( {} )()
	local o = d.newText()
	o:setReferencePoint( d.BottomRightReferencePoint )
	assert_equal( 1, o.anchorX ) ; assert_equal( 1, o.anchorY )
	o:setReferencePoint( d.TopCenterReferencePoint )
	assert_equal( 0.5, o.anchorX ) ; assert_equal( 0, o.anchorY )
end

-- Solar2D's own constants were ignored
function test_solar2d_reference_points()
	local d = load( {} )()
	local o = d.newRect()
	o:setReferencePoint( display.TopLeftReferencePoint )
	assert_equal( 0, o.anchorX ) ; assert_equal( 0, o.anchorY )
	o:setReferencePoint( SOLAR2D_CENTER )
	assert_equal( 0.5, o.anchorX ) ; assert_equal( 0.5, o.anchorY )
	assert_error_match( 'takes a reference point.*got nil', function() o:setReferencePoint( d.Nowhere ) end )
end

function test_methods_per_object()
	local d, n = load( {} )()
	local function has( o, name ) return o[ '_'..name ] ~= nil end
	local rect, line, group = d.newRect(), d.newLine(), d.newGroup()
	assert_true( has( rect, 'setFillColor' ) and has( rect, 'setStrokeColor' ) )
	assert_false( has( line, 'setFillColor' ) )
	assert_true( has( line, 'setStrokeColor' ) )
	assert_false( has( group, 'setFillColor' ) )
	assert_equal( 'function', type( group.setAnchor ) )
	-- newPolygon kept Solar2D's 0-1 setFillColor
	local poly = d.newPolygon()
	poly:setFillColor( 255, 0, 0 )
	assert_color( { 1, 0, 0, 1 }, lastCall( poly ) )
end

-- newImage() and newImageRect() raised "attempt to index nil"
function test_missing_image()
	local d = load( {} )()
	assert_nil( d.newImage( 'missing.png' ) )
	assert_nil( d.newImageRect( 'missing.png', 10, 10 ) )
	assert_equal( 'function', type( d.newImage( 'a.png' ).setAnchor ) )
end

-- setFillColor() raised "attempt to call nil": fields have setTextColor()
function test_native()
	local d, n = load( {} )()
	local field, box, web = n.newTextField(), n.newTextBox(), n.newWebView()
	field:setTextColor( 255, 0, 0 )
	assert_equal( 'setTextColor', lastCall( field ).name )
	assert_color( { 1, 0, 0, 1 }, lastCall( field ) )
	box:setTextColor( '#00FF00' )
	assert_color( { 0, 1, 0 }, lastCall( box ) )
	assert_nil( field._setFillColor )
	assert_nil( web._setFillColor )
	assert_nil( web._setTextColor )
	assert_equal( 'function', type( web.setAnchor ) )
end

function test_activate_off()
	local d = load( { activate_anchor=false, activate_fillcolor=false,
		activate_strokecolor=false } )()
	local o = d.newRect()
	assert_nil( o.setAnchor )
	assert_nil( o._setFillColor )
	assert_nil( o._setStrokeColor )
end

-- without :BOOL, 'false' was a string, which counts as on
function test_config_strings()
	local d = load( { activate_anchor='false', make_global='false' } )()
	assert_nil( d.newRect().setAnchor )
	assert_nil( _G.display.NAME )
end

function test_make_global()
	local solar2d_display, solar2d_native = _G.display, _G.native
	local d, n = load( { make_global=true } )()
	local ok_d, ok_n = _G.display == d, _G.native == n
	_G.display, _G.native = solar2d_display, solar2d_native
	assert_true( ok_d )
	assert_true( ok_n )
end

-- the config from the file, through the boot loader
function test_config_types()
	cfgFile = 'tests/typed.cfg'
	local d = load( nil )()
	cfgFile = 'dmc_corona.cfg'
	local o = d.newRect()
	assert_nil( o.setAnchor )
	o:setFillColor( 0, 0, 0, 51 )
	assert_color( { 0, 0, 0, 0.2 }, lastCall( o ) )
end
