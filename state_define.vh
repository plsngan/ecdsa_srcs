`timescale 1ns/1ps

//`define prime 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
`define prime 256'hFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551
`define Gx    256'h79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
`define Gy    256'h483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8

// Multiplier state
`define Init      0   //state
`define Mul1      1   //state
`define Mul2      2   //state
`define Mul3      3   //state
`define Mul4      4   //state
`define Mul5      5   //state
`define Mul6      6   //state
`define Mul7      7   //state
`define Mul8      8   //state
`define Mul9      9   //state
`define Mul10    10   //state
`define Mul11    11   //state
`define Mul12    12   //state
`define Mul13    13   //state
`define Mul14    14   //state
`define Mul15    15   //state
`define Mul16    16   //state
`define Add      17   //state
`define Final    18   //state

// Modular Reduction state
`define Init     0   //state
`define Mod1     1   //state
`define Mod2     2   //state
`define Mod3     3   //state
`define Mod4     4   //state
`define Mod5     5   //state
`define Mod6     6   //state
`define Mod7     7   //state
`define Mod8     8   //state
`define Finish   9  //state

// Modular Inversion state
`define Init     0   //state
`define ModInv   1   //state
`define invFinal 2   //state

// ECCcore state
`define Init      0   //state
`define Hash      1   //state
`define XYZ       2   //state
`define ML        3   //state
`define xy        4   //state
`define Sign      5   //state
//`define Verify    6   //state

`define conv0a  0     //state
`define conv0b  1     //state
`define conv0c  2     //state
`define conv0d  3     //state
`define conv1a  4     //state
`define conv1b  5     //state
`define conv1c  6     //state
`define conv1d  7     //state
`define conv2a  8     //state
`define conv2b  9     //state
`define conv2c  10    //state
`define conv2d  11    //state
`define conv3a  12    //state
`define conv3b  13    //state
`define conv3c  14    //state
`define conv3d  15    //state
`define conv4a  16    //state
`define conv4b  17    //state
`define conv4c  18    //state
`define conv4d  19    //state
`define conv5a  20    //state
`define conv5b  21    //state
`define conv5c  22    //state
`define conv5d  23    //state
`define conv_final  24//state

`define Double1a  0   //state
`define Double1b  1   //state
`define Double1c  2   //state
`define Double1d  3   //state
`define Double1e  4   //state
`define Double1f  5   //state
`define Double1g  6   //state
`define Double1h  7   //state
`define Double2a  8   //state
`define Double2b  9   //state
`define Double2c  10   //state
`define Double2d  11   //state
`define Double2e  12   //state
`define Double2f  13   //state
`define Double2g  14   //state
`define Double2h  15   //state
`define Double3a  16   //state
`define Double3b  17   //state
`define Double3c  18   //state
`define Double3d  19   //state
`define Double4a  20   //state
`define Double4b  21   //state
`define Double4c  22   //state
`define Double4d  23   //state
`define Double5a  24   //state
`define Double5b  25   //state
`define Double5c  26   //state
`define Double5d  27   //state
`define Double5e  28   //state
`define Double5f  29   //state
`define Double6a  30   //state
`define Double6b  31   //state
`define Double6c  32   //state
`define Double6d  33   //state
`define Double6e  34   //state
`define Double6f  35   //state
`define Double6g  36   //state
`define Double6h  37   //state
`define Double7a  38   //state
`define Double7b  39   //state
`define Double7c  40   //state
`define Double7d  41   //state
`define Double8a  42   //state
`define Double8b  43   //state
`define Double8c  44   //state
`define Double8d  45   //state
`define Double8e  46   //state
`define Double8f  47   //state
`define Add1a     48   //state
`define Add1b     49   //state
`define Add1c     50   //state
`define Add1d     51   //state
`define Add2a     52   //state
`define Add2b     53   //state
`define Add2c     54   //state
`define Add2d     55   //state
`define Add3a     56   //state
`define Add3b     57   //state
`define Add3c     58   //state
`define Add3d     59   //state
`define Add4a     60   //state
`define Add4b     61   //state
`define Add4c     62   //state
`define Add4d     63   //state
`define Add5a     64   //state
`define Add5b     65   //state
`define Add5c     66   //state
`define Add5d     67   //state
`define Add6a     68   //state
`define Add6b     69   //state
`define Add6c     70   //state
`define Add6d     71   //state
`define Add7a     72   //state
`define Add7b     73   //state
`define Add7c     74   //state
`define Add7d     75   //state
`define Add8a     76   //state
`define Add8b     77   //state
`define Add8c     78   //state
`define Add8d     79   //state
`define Add9a     80   //state
`define Add9b     81   //state
`define Add9c     82   //state
`define Add9d     83   //state
`define Add10a    84   //state
`define Add10b    85   //state
`define Add10c    86   //state
`define Add10d    87   //state
`define Add11a    88   //state
`define Add11b    89   //state
`define Add11c    90   //state
`define Add11d    91   //state
`define Add12a    92   //state
`define Add12b    93   //state
`define Add12c    94   //state
`define Add12d    95   //state
`define Add13a    96   //state
`define Add13b    97   //state
`define Add13c    98   //state
`define Add13d    99   //state
`define Add14a    100   //state
`define Add14b    101   //state
`define Add14c    102   //state
`define Add14d    103   //state
`define Add15a    104   //state
`define Add15b    105   //state
`define Add15c    106   //state
`define Add15d    107   //state
`define Add15e    108   //state
`define Add15f    109   //state
`define Add16a    110   //state
`define Add16b    111   //state
`define Add16c    112   //state
`define Add16d    113   //state
`define Add16e    114   //state
`define Add16f    115   //state
`define Add17a    116   //state
`define Add17b    117   //state
`define Add17c    118   //state
`define Add17d    119   //state
`define Add18a    120   //state
`define Add18b    121   //state
`define Add18c    122   //state
`define Add18d    123   //state
`define Add18e    124   //state
`define Add18f    125   //state
`define MLswap    126   //state
`define MLshift   127   //state

`define Sign0a   0   //state
`define Sign0b   1   //state
`define Sign0c   2   //state
`define Sign0d   3   //state
`define Sign1a   4   //state
`define Sign1b   5   //state
`define Sign1c   6   //state
`define Sign1d   7   //state
`define Sign2a   8   //state
`define Sign2b   9   //state
`define Sign2c   10  //state
`define Sign2d   11  //state
`define Sign2e   12  //state
`define Sign2f   13  //state
`define Sign3a   14  //state
`define Sign3b   15  //state
`define Sign3c   16  //state
`define Sign3d   17  //state
`define Sign4a   18  //state
`define Sign4b   19  //state
`define Sign4c   20  //state
`define Sign4d   21  //state
`define Sign_end 22  //state