`define ImageDimX 1280
`define ImageDimY 960
`define ImageBitDepth 12
`define ImageMemSize ( `ImageDimX * `ImageDimY )
`define ImageAddrWidth ( $clog2(`ImageMemSize) )
