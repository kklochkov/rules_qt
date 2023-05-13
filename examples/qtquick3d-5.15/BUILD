_EXAMPLES = [
    "examples/quick3d/dynamictexture",
    "examples/quick3d/dynamiccreation",
    "examples/quick3d/hellocube",
    "examples/quick3d/simple",
    "examples/quick3d/picking",
    "examples/quick3d/lights",
    "examples/quick3d/view3d",
    "examples/quick3d/principledmaterial",
    "examples/quick3d/effects",
    "examples/quick3d/customshaders",
    "examples/quick3d/custommaterial",
    "examples/quick3d/antialiasing",
    "examples/quick3d/quickitems",
]

[
    alias(
        name = example.replace(":", "_"),
        actual = "@qtquick3d-5.15//" + example,
    )
    for example in _EXAMPLES
]
