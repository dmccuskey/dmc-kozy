# dmc-kozy

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-kozy"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-kozy",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_kozy.lua"
		],
		"requires": [
			"dmc-corona-boot"
		]
	},
	"examples": {
		"dir": "examples",
		"apps": []
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-kozy", module_config )

