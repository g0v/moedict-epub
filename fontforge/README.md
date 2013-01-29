Subsetted and extended fonts for MoE Dictionary
===============================================

Fonts are from Han Nom project. **Commercial use is strictly forbidden.**

Subsetting
-----------
The `subset.py` is Modififed from Google Font Dictionary project.
When you need to subset from certain font, use this command:

    ./subset.py --stringfile [text file for subsetting] [source file] [output file]

Extended fonts
--------------

The extended fonts are from FontForge, and its source file is provided.
The glyphs are encoded at Unicode user defined area at U+F0000 + original encode.

For example:

* 8ff0 ⿰亻壯 is at U+F8FF0 󸿰
* 9868 ⿱禾千 is at U+F9868 󹡨
