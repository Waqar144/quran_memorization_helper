import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

bool _shouldAddSpaces(int pageNum, int lineIdx) {
  const pageToLines = <int, List<int>>{
    // para 1
    1: [0, 1, 2, 3, 4, 5, 6],
    2: [1, 2, 3, 4, 5],
    4: [2, 3, 4, 5, 6, 8, 12],
    5: [2, 5, 11],
    6: [8, 13],
    7: [7, 11],
    8: [5, 13, 15],
    9: [0, 4, 8, 9, 12, 15],
    10: [0, 1, 2, 3, 4, 6, 7, 8, 10, 12, 14],
    11: [1, 2, 3, 4, 5, 8, 10, 13, 14],
    12: [5, 14],
    13: [2],
    14: [1, 6, 7],
    15: [8, 12, 13],
    16: [1, 2, 3, 4, 6, 7, 8, 12, 13],
    17: [2, 3, 7, 11, 12, 13, 14],
    // para 2
    20: [0, 5, 12],
    21: [12, 13, 14],
    22: [2, 3, 5, 12, 13, 14],
    23: [0, 1, 2, 3, 4, 5, 7, 11],
    24: [1, 3, 7, 8, 9, 10],
    25: [0, 1, 5, 6, 7, 8, 11, 12],
    26: [4, 5, 6, 15],
    27: [2, 7, 8, 11],
    28: [0, 2, 7, 8, 9, 12, 14, 15],
    29: [4, 5, 11, 13],
    30: [0, 3, 4, 6, 12],
    31: [8],
    32: [2, 3, 4, 5, 6, 10, 11, 12, 14],
    33: [1, 7, 8, 9, 11, 12],
    34: [1, 4, 6, 8],
    35: [0, 5, 8, 9, 10],
    // para 3
    38: [0, 1, 6, 8, 9, 10, 11, 12, 15],
    39: [2, 3, 4, 5, 7, 9, 11, 14],
    40: [2, 3, 4, 5, 6, 7, 8, 9, 15],
    41: [0, 1, 5, 6, 10, 11, 15],
    42: [1, 4, 5, 7, 8, 9, 10, 13, 15],
    43: [0, 4, 10, 11, 15],
    44: [1, 4, 5, 7, 9, 10, 11, 12, 13, 15],
    45: [0, 2, 6, 7, 8, 11, 12, 13, 14],
    46: [2, 4, 5, 6, 7, 9],
    47: [2, 5, 6, 7, 10],
    48: [5, 8, 9],
    49: [5, 6, 14, 15],
    50: [1, 3, 4, 11, 14],
    51: [0, 3, 10, 13],
    52: [5, 11, 14],
    53: [0, 4, 6, 7, 8, 9, 11, 12, 14, 15],
    54: [1, 2, 4, 5, 7, 14],
    55: [1, 2, 3, 4, 5, 7, 8, 9, 11, 12],
    // para 4
    56: [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 15],
    57: [2, 6, 7, 8, 10, 13],
    58: [0, 6, 8, 14],
    59: [3, 8, 12, 13],
    60: [6, 7, 8, 14],
    61: [0, 4, 5, 8, 14],
    62: [0, 1, 4, 5, 7, 10, 13],
    63: [0, 1, 4, 5, 7, 8, 9, 11, 12],
    64: [1, 2, 3, 5, 6],
    65: [12, 13],
    66: [3, 4, 7, 12, 15],
    67: [2, 4, 5, 6, 7, 8, 15],
    68: [1, 3, 4, 6, 7, 8, 10, 12, 14],
    69: [0, 1, 2, 4, 6, 7, 8, 11, 13, 14],
    70: [6, 9, 10, 11, 12],
    71: [2, 5, 6, 7, 8, 9, 10, 14],
    72: [0, 1, 3, 4, 6, 7, 8, 13],
    73: [15],
    // para 5
    74: [2, 9, 15],
    75: [1, 3, 4, 6, 8, 10],
    76: [0, 3, 7, 8, 9, 10, 12],
    77: [3, 5, 6, 7, 8, 9, 10, 11, 12],
    78: [0, 2, 4, 6, 9],
    79: [4, 5, 6],
    80: [0, 1, 2, 3, 4, 6, 9, 13, 14, 15],
    81: [1, 2, 3, 6, 11, 12, 13, 15],
    82: [0, 1, 4, 6, 11, 12],
    83: [3, 4, 6, 8, 9, 12],
    84: [4, 7, 9],
    85: [8],
    86: [2, 3],
    87: [0],
    88: [0, 2, 4, 9, 11],
    89: [1, 2, 4, 9, 11],
    90: [1, 3, 5, 6, 7, 8, 9, 10, 12],
    91: [0, 8, 9],
    // para 6
    92: [0, 1, 2, 3, 5, 13, 14],
    93: [0, 3, 4, 5, 6, 7, 8, 9, 10, 15],
    94: [0, 1, 3, 10, 12, 15],
    95: [0, 2, 6, 7, 8, 10, 13, 15],
    96: [0, 2, 8, 10, 12, 14],
    97: [4, 9, 11, 13],
    98: [1, 2, 3, 5, 6, 12],
    99: [1, 2, 3, 4, 7, 8, 12, 15],
    100: [1, 5, 6, 7, 8, 10, 13, 15],
    101: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 15],
    102: [0, 5],
    103: [0, 2, 3, 7, 9, 14],
    104: [2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 15],
    105: [3, 9, 13],
    106: [2, 5, 8, 12],
    107: [2, 7, 10, 12],
    108: [11, 12, 13],
    109: [2, 5],
    // para 7
    110: [0, 2, 3, 4, 7, 13],
    111: [4],
    113: [8],
    114: [2, 3, 4, 7, 13],
    115: [2, 3],
    116: [14],
    117: [1],
    118: [0],
    119: [4, 10, 15],
    120: [4],
    121: [5, 7, 8],
    122: [7],
    123: [4, 14],
    125: [5],
    126: [10, 11],
    127: [0, 2, 6, 9, 11, 14, 15],
    // para 8
    128: [1, 3, 4, 5, 6, 8, 10, 11, 12],
    129: [1, 2, 4, 6, 10, 11],
    130: [6],
    131: [0, 2, 3, 6, 7, 13],
    132: [1, 7, 11, 14, 15],
    133: [6],
    134: [1, 6, 9, 12, 15],
    135: [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15],
    136: [1, 2, 3, 5, 8, 10, 12, 15],
    137: [0, 1, 7],
    138: [1],
    139: [0, 4, 12],
    140: [0, 9, 13, 14],
    141: [13, 15],
    142: [2, 6, 8, 13],
    143: [0, 5, 8, 10, 12, 13, 14],
    144: [0, 7, 10, 12, 13, 15],
    145: [10, 11, 15],
    // para 9
    146: [2, 3, 4, 5, 12, 14],
    147: [14],
    148: [11, 14],
    149: [1, 6, 9, 12, 13, 15],
    150: [1, 3, 6, 8, 9, 14],
    151: [3, 4, 5, 6, 8, 10, 11, 12, 13, 15],
    152: [0, 1, 2, 4, 5, 8, 13],
    153: [1, 6, 7, 12, 14],
    154: [3, 12],
    155: [2, 6, 7, 8, 10, 15],
    156: [0, 3, 4, 5, 6, 13],
    157: [3, 5, 10, 12, 15],
    158: [2, 3, 7, 9, 14, 15],
    159: [1, 2, 3, 6, 8, 12, 15],
    160: [3, 5, 8, 10, 13, 14, 15],
    161: [0, 1, 2, 3, 4, 6, 11, 12, 13, 14, 15],
    162: [1, 3, 4, 6, 7, 8, 10, 13, 14],
    163: [0, 2, 4, 7, 10, 11, 12, 13, 14, 15],
    164: [1, 2, 3, 4, 6, 7, 9, 11, 15],
    165: [0, 1, 2, 3, 4, 5, 6, 11, 12, 13, 14, 15],
    166: [0, 2, 3, 4, 5, 8, 9, 13, 14],
    167: [1, 4, 5, 6, 7, 8, 10, 11, 12, 13],
    168: [0, 1, 3, 4, 5, 6, 7, 10, 13, 15],
    169: [1, 4, 7, 10, 11, 13, 14],
    170: [0, 1, 3, 5, 10, 12, 13, 14],
    171: [0, 1, 4, 5, 6, 9, 11],
    172: [0, 3, 4, 8, 9, 10, 11, 12, 14, 15],
    173: [1, 4, 6, 7, 8, 9, 13, 15],
    174: [2, 8, 9, 10, 11, 14, 15],
    175: [1, 3, 5, 6, 9, 12, 14, 15],
    176: [6, 7, 8, 10, 11, 12, 14, 15],
    177: [2, 5, 6, 7, 9, 11, 13, 14, 15],
    178: [0, 4, 5, 6, 7, 9, 10, 13, 14],
    179: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14],
    180: [2, 3, 6, 8, 9, 10, 12, 14],
    181: [0, 2, 3, 5, 7, 8, 9, 10, 11, 13],
    182: [0, 2, 4, 8, 10, 15],
    184: [2, 3, 6, 7, 15],
    185: [4, 8, 12, 15],
    186: [0, 3, 12],
    187: [0, 1, 4, 5, 7, 8, 10, 14],
    189: [0, 1, 6, 9],
    190: [8],
    191: [15],
    192: [0, 12, 15],
    193: [3, 8, 9, 10, 11],
    194: [4, 5, 6, 9, 13],
    195: [2, 3, 8, 9, 10],
    196: [5, 8, 9, 10],
    197: [0, 1, 2, 5, 11],
    198: [0, 1, 2, 3, 6, 8, 9, 12, 13, 14],
    199: [4, 6, 9, 10, 11, 12, 13, 14],
    200: [0, 2, 5],
    201: [4, 10, 15],
    202: [8, 14, 15],
    203: [3, 5, 6, 8, 12, 13, 14],
    204: [1, 2, 6, 7],
    205: [5, 6, 11, 15],
    206: [0, 5, 9, 11, 13, 15],
    207: [3, 6, 8, 12, 13, 15],
    208: [2, 12, 13],
    209: [11, 12],
    210: [1, 3, 12],
    211: [3, 5, 6, 12, 13],
    212: [1, 6, 12],
    213: [4, 8, 9, 10],
    214: [1, 6, 10, 11, 12],
    215: [5, 9, 15],
    216: [1, 2, 5, 6, 7, 9, 10, 13, 14],
    217: [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15],
    218: [0, 6, 11, 12, 14, 15],
    219: [1, 4, 5, 6, 10],
    220: [2, 5, 10],
    221: [1, 2, 4, 5, 6, 13, 14, 15],
    222: [5, 9, 11, 13],
    223: [1, 6, 8, 9, 13],
    224: [0, 1, 6, 8, 9, 12, 13, 15],
    225: [3, 5, 7, 9, 10, 11, 13],
    226: [0, 9],
    227: [8, 9, 13],
    228: [1, 3, 6, 7, 10, 12, 13],
    229: [1, 4, 6, 7, 9, 10, 11, 14],
    230: [0, 4, 6, 7, 8, 9, 11, 15],
    231: [2, 3, 7, 8, 9, 11, 12, 13, 14, 15],
    232: [1, 7, 9, 10, 11],
    233: [1, 5, 6, 15],
    234: [5, 6, 9, 11],
    235: [13, 15],
    236: [2, 3, 5, 6, 7, 13, 14, 15],
    237: [0, 10, 13],
    // para 14
    238: [1, 2, 4, 5, 7, 8, 11],
    239: [6, 7, 10, 11, 12, 14],
    240: [4, 5, 12],
    241: [0, 2, 10, 14],
    242: [8, 10],
    243: [12, 13, 15],
    244: [0, 1, 2, 5, 8, 10],
    245: [5, 6, 7, 8, 9, 15],
    246: [1, 2, 3, 12, 13, 15],
    247: [0, 1, 2, 5, 7, 8, 11, 13, 15],
    248: [1, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14],
    249: [0, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15],
    250: [0, 1, 2, 7, 9, 11, 12, 13],
    251: [1, 5, 7, 9, 10, 11, 13, 15],
    252: [0, 2, 3, 5, 6, 8, 10, 15],
    253: [0, 2, 3, 9, 15],
    // para 15
    254: [1, 4, 5, 14],
    255: [2, 4, 5, 8, 10, 12, 13, 14, 15],
    256: [2, 4, 6, 9, 11],
    257: [3, 4, 5, 12, 14],
    258: [1, 6, 10],
    259: [0, 1, 5, 11],
    260: [8],
    261: [0, 2, 8],
    262: [10],
    264: [0, 6, 8, 10, 11, 13],
    265: [1, 8],
    266: [3, 13],
    268: [5],
    272: [0, 1, 3],
    273: [0, 1, 8, 9, 10],
    274: [0, 4],
    276: [4, 6, 9],
    277: [3, 7, 8],
    278: [4, 12],
    281: [0, 3, 4, 8],
    284: [9, 10],
    285: [11, 14, 15],
    287: [5],
    288: [2, 5, 12],
    290: [1, 2, 5, 6, 8, 9, 11, 12, 13, 14],
    291: [6, 9, 10, 13, 14, 15],
    292: [0, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    293: [2, 3, 4, 5, 6, 8, 9, 10, 14, 15],
    294: [1, 2, 4, 5, 6, 7, 8, 10, 13, 14, 15],
    295: [4, 7, 13, 15],
    296: [0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 15],
    297: [0, 3, 11, 13, 15],
    298: [2, 6, 7, 8, 10, 11, 12, 13, 14, 15],
    299: [2, 3, 5, 6, 8, 9, 12, 14],
    300: [0, 1, 2, 3, 4, 5, 6, 9, 12, 13],
    301: [0, 1, 2, 4, 5, 10],
    302: [0, 2, 4, 9, 10, 11, 13, 14],
    303: [2],
    304: [1, 4, 5, 6, 7, 9, 10, 12, 15],
    305: [3, 11, 12, 13, 14, 15],
    306: [0, 5, 8, 11, 12, 13, 14],
    307: [1, 2, 5, 6, 7, 11, 12, 13, 15],
    308: [3, 8, 14],
    309: [8, 11, 12],
    311: [3, 9, 15],
    312: [11],
    313: [0, 3, 4, 5, 10, 11, 14],
    314: [1, 3, 10],
    315: [4, 8, 13, 14],
    316: [3, 12, 15],
    317: [2, 5],
    319: [3],
    320: [10],
    322: [10],
    324: [1, 5, 9, 10],
    325: [10],
    326: [0, 7, 8],
    327: [0],
    329: [15],
    330: [2, 12],
    331: [1, 11, 12, 13],
    332: [3, 8, 14],
    333: [2, 4, 5, 9],
    334: [10],
    335: [9],
    338: [4],
    340: [7, 8, 9],
    342: [0],
    344: [6, 8, 12, 13],
    345: [3, 4, 5, 6, 8, 9],
    346: [1, 3, 4, 5, 7, 10, 11, 13, 15],
    347: [2, 3, 4, 6, 8, 9, 10, 11, 13, 14],
    348: [0, 1, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14],
    349: [0, 1, 3, 4, 5, 7, 8, 9, 10, 12, 14],
    350: [1, 3, 6, 7, 9, 12, 14],
    351: [0, 1, 2, 4, 5, 6, 7, 9, 10, 11, 14, 15],
    352: [0, 2, 4, 5, 6, 7, 9, 10, 11, 12],
    353: [1, 3, 7, 8, 12, 14, 15],
    354: [0, 1, 13, 15],
    355: [1, 3, 8, 9, 10, 12, 13, 14, 15],
    356: [0, 1, 2, 3, 4, 5, 7, 8, 10, 11, 12, 13, 14, 15],
    357: [0, 1, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15],
    358: [2, 3, 4, 8, 11, 14],
    359: [5, 7, 8, 9, 10, 13, 14, 15],
    360: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    361: [7, 11, 13, 15],
    362: [2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
    363: [0, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 15],
    364: [0, 5, 6, 7, 8, 9, 11, 12],
    365: [0, 2, 3, 5],
    366: [7, 8, 10, 14],
    367: [1, 3, 9, 10],
    368: [2, 10, 11],
    369: [3, 4, 11],
    370: [2, 4, 5, 8, 9, 11, 12, 13],
    371: [4, 8, 13],
    372: [1],
    373: [13],
    376: [5],
    377: [1, 15],
    378: [0, 1, 4, 5, 6, 7, 11, 12],
    379: [0, 4],
    380: [0, 3, 4, 5, 6, 13, 15],
    381: [0, 6],
    382: [0, 13, 14, 15],
    383: [0, 1, 10, 12, 14, 15],
    384: [2, 3, 5, 7, 9, 10, 11, 12],
    385: [4, 5, 7, 9, 12, 13, 14],
    386: [3, 5, 7, 11, 14, 15],
    387: [0, 5, 15],
    388: [0, 1, 2, 4, 8, 13],
    389: [0],
    390: [0, 15],
    391: [1, 2, 4, 5, 7, 14],
    392: [8],
    393: [9],
    394: [12],
    396: [9, 13, 14],
    397: [0, 1, 2, 5, 6, 7, 14],
    398: [7],
    399: [5],
    400: [13],
    402: [0, 15],
    403: [7],
    404: [11, 12],
    405: [3, 7, 11],
    406: [5, 8],
    407: [0, 9],
    408: [0, 8],
    412: [11],
    413: [7],
    415: [11],
    // para 24
    416: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    417: [0, 1, 2, 3, 4, 8, 10, 12, 13, 14],
    418: [0, 1, 2, 5, 9, 11, 12, 13, 14],
    419: [4, 6, 11, 12, 14, 15],
    420: [6, 8, 9, 13, 14, 15],
    421: [8, 10],
    422: [9, 10],
    423: [3, 5, 7, 8, 11, 12],
    424: [5, 9, 10, 14, 15],
    425: [2, 4, 10],
    426: [0, 2, 4, 5, 6, 9, 10, 13],
    427: [3, 4, 5, 6, 7, 9, 14],
    428: [3, 4, 5, 6, 7, 10, 12, 13, 15],
    429: [0, 2, 3, 8, 14],
    430: [8, 13],
    431: [3, 4, 5, 7, 9, 11, 12, 13, 14, 15],
    432: [1, 3, 5, 8, 9, 10, 11, 12, 13, 14, 15],
    433: [0, 2, 3, 6, 8, 9, 10, 11, 12, 13, 15],
    // para 25
    434: [12, 13],
    435: [9, 11],
    436: [0, 1, 3, 10],
    437: [1, 4, 6, 10, 11, 13],
    438: [0, 1, 4, 7, 13],
    439: [0, 1, 2, 4, 6, 7, 12, 13],
    440: [6, 10],
    441: [0, 6, 8],
    442: [3, 8],
    444: [2, 12],
    445: [2, 3],
    446: [1, 7],
    448: [8, 13],
    // para 26
    452: [6, 12],
    453: [0, 1, 10, 11, 12, 13],
    454: [1, 3, 9],
    455: [9, 10],
    456: [0, 5],
    462: [6, 10],
    463: [2],
    464: [14],
    466: [3, 7],
    467: [8],
    468: [4],
    469: [5],
    // para 27
    471: [5],
    473: [7, 14],
    474: [2, 3],
    475: [7],
    478: [4],
    480: [12, 14, 15],
    481: [9],
    482: [5, 13],
    483: [11],
    484: [0],
    485: [3, 9],
    486: [1, 9, 13],
    487: [1, 14, 15],
    // para 28
    488: [1, 3, 4, 6, 7, 8, 10, 11, 12, 13, 14],
    489: [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 13],
    490: [1, 2, 3, 5, 6, 7, 8, 10, 11, 14],
    491: [0, 2, 4, 5, 8, 9, 12, 14],
    492: [2, 3, 5, 7, 9, 10, 11, 12, 13, 14, 15],
    493: [0, 1, 2, 4, 5, 6, 8, 12, 14, 15],
    494: [0, 1, 2, 4, 5, 11, 12],
    495: [1, 3, 4, 5, 6, 9, 11, 12, 13, 14],
    496: [1, 3, 4, 5, 6, 7, 11, 13],
    497: [6, 7, 8, 9, 10, 12],
    498: [1, 3, 4, 6, 7, 9, 11, 13],
    499: [1, 3, 4, 5, 6],
    500: [2, 3, 8, 9, 11, 12],
    501: [4, 9, 10, 11, 12, 13, 15],
    502: [2, 3, 5, 10, 11, 12],
    503: [4, 7, 8],
    504: [5, 6, 7, 10, 12, 14],
    505: [1, 2, 3, 6, 7, 8, 10, 11],
    506: [2, 7, 8, 9, 10, 12, 13],
    507: [6, 15],
    // para 29
    508: [1, 3, 4, 9, 12],
    509: [13],
    510: [1, 3, 5, 11, 14],
    511: [7, 8, 10, 13],
    512: [0, 1, 2, 3, 7, 8, 10, 15],
    513: [5, 6, 9, 11, 13, 14],
    514: [2, 3, 6, 8, 12, 14],
    515: [3, 6, 8, 10, 13],
    516: [2, 4, 6, 8, 10],
    517: [0, 10, 12],
    518: [0, 1, 2, 3, 5, 14, 15],
    519: [11, 14],
    520: [1, 5],
    521: [1, 2, 5, 9, 13],
    522: [9],
    523: [6, 14],
    524: [5, 8, 10],
    525: [7],
    526: [6, 13],
    527: [3, 4, 7, 8, 10, 14, 15],
    // para 30
    528: [1],
    529: [10],
    530: [9, 12],
    531: [5, 11, 13, 14, 15],
    532: [10, 11, 13],
    533: [14, 15],
    534: [2, 12],
    535: [9, 13],
    536: [1, 7, 15],
    537: [5, 6, 9],
    538: [4, 5, 14],
    539: [4, 6, 8, 9, 10, 13, 15],
    540: [9, 11, 12, 15],
    541: [0, 2, 3, 4, 6, 9, 10, 13, 15],
    542: [4, 5, 10, 12, 13, 14, 15],
    543: [1, 5, 6, 12, 13, 14, 15],
    544: [5, 11, 15],
    545: [1, 4, 6, 8, 11],
    546: [2, 3, 5, 7, 10, 12, 14, 15],
    547: [1, 2, 3, 10, 13],
    548: [1, 2, 3, 5, 6, 7],
  };
  return pageToLines[pageNum]?.contains(lineIdx) ?? false;
}

final _markedWordStyle = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.shade100,
  color: Colors.red,
);
final _markedAyahBGStyle = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.shade100,
);
final _markedMutAyahBGStyle = TextStyle(
  inherit: true,
  color: Colors.indigo,
  backgroundColor: Colors.red.shade100,
);
const TextStyle _mutStyle = TextStyle(inherit: true, color: Colors.indigo);

class LineAyah {
  final int ayahIndex;
  final String text;
  const LineAyah(this.ayahIndex, this.text);
}

class Line {
  final List<LineAyah> lineAyahs;
  const Line(this.lineAyahs);
}

class Page {
  final int pageNum;
  final List<Line> lines;
  const Page(this.pageNum, this.lines);

  static Page fromJson(dynamic json, List<int> surahAyahStarts) {
    int pageNum = json["pageNum"] as int;
    List<dynamic> lineDatas = json["lines"] as List<dynamic>;
    List<Line> lines = [];
    for (final lineData in lineDatas) {
      final lineArray = lineData as List<dynamic>;
      List<LineAyah> lineAyahs = [];

      int firstAyahIdx = lineArray.first['idx'] as int;
      if (surahAyahStarts.lastOrNull == firstAyahIdx) {
        int surah = getSurahAyahStarts().indexOf(surahAyahStarts.last);
        assert(surah != -1);
        lines.add(Line([LineAyah(-surah, "")]));
        surahAyahStarts.removeLast();
      }

      for (final lineArrayItem in lineArray) {
        int ayahIdx = lineArrayItem['idx'] as int;
        final ayahText = lineArrayItem['text'] as String;
        lineAyahs.add(LineAyah(ayahIdx, ayahText));
      }
      lines.add(Line(lineAyahs));
    }
    return Page(pageNum, lines);
  }
}

class ReadQuranWidget extends StatefulWidget {
  final ParaAyatModel model;

  const ReadQuranWidget(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _ReadQuranWidget();
}

class _ReadQuranWidget extends State<ReadQuranWidget>
    with SingleTickerProviderStateMixin {
  List<Line> lines = [];
  List<Page> _pages = [];
  List<Mutashabiha> _mutashabihat = [];
  ByteBuffer? _quranUtf8;
  final _repaintNotifier = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // disable auto screen turn off
  }

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable();
  }

  Future<List<Page>> doload() async {
    int para = widget.model.currentPara;
    final data = await rootBundle.loadString("assets/16line/$para.json");
    List<dynamic> pagesList = jsonDecode(data);
    List<Page> pages = [];
    List<int> surahAyahStarts =
        surahAyahOffsetsForPara(para - 1).reversed.toList();
    for (final p in pagesList) {
      pages.add(Page.fromJson(p, surahAyahStarts));
    }
    _pages = pages;

    // we lazy load the mutashabiha ayat text
    _mutashabihat = await importParaMutashabihas(para - 1, null);
    return _pages;
  }

  bool _isMutashabihaAyat(int surahAyahIdx, int surahIdx) {
    for (final m in _mutashabihat) {
      if (m.src.surahIdx == surahIdx &&
          m.src.surahAyahIndexes.contains(surahAyahIdx)) {
        return true;
      }
    }
    return false;
  }

  List<Mutashabiha> _getMutashabihaAyat(int surahAyahIdx, int surahIdx) {
    List<Mutashabiha> ret = [];
    for (final m in _mutashabihat) {
      if (m.src.surahIdx == surahIdx &&
          m.src.surahAyahIndexes.contains(surahAyahIdx)) {
        ret.add(m);
      }
    }
    return ret;
  }

  Ayat? _getAyatInDB(int surahAyahIdx, int surahIdx) {
    int abs = toAbsoluteAyahOffset(surahIdx, surahAyahIdx);
    for (final a in widget.model.ayahs) {
      if (a.ayahIdx == abs) return a;
    }
    return null;
  }

  String _getFullAyahText(int ayahIdx, int pageNum) {
    int pageIndex = pageNum - _pages[0].pageNum;
    int startPage = pageIndex == 0 ? pageIndex : pageIndex - 1;
    int endPage = pageNum == _pages.last.pageNum ? pageIndex : pageIndex + 1;

    bool foundStart = false;
    String text = "";

    for (int p = startPage; p <= endPage; p++) {
      Page page = _pages[p];
      for (final line in page.lines) {
        for (final lineAyah in line.lineAyahs) {
          if (lineAyah.ayahIndex == ayahIdx) {
            if (!foundStart) {
              foundStart = true;
            }
            text += lineAyah.text;
            text += "\u200c";
          } else {
            if (foundStart) {
              break;
            }
          }
        }
      }
    }
    return text;
  }

  (bool isFull, bool atPageStart, bool atPageEnd) _isAyahFull(
      int ayahIdx, int pageNum) {
    bool isFull = true;
    bool isAtPageEnd = false;
    bool isAtPageStart = false;
    int pageIndex = pageNum - _pages[0].pageNum;

    isAtPageEnd =
        _pages[pageIndex].lines.last.lineAyahs.last.ayahIndex == ayahIdx;
    isAtPageStart =
        _pages[pageIndex].lines.first.lineAyahs.first.ayahIndex == ayahIdx;

    if (isAtPageEnd && (pageIndex + 1) < _pages.length) {
      // next page first ayah != this ayah => we have a full ayah
      isFull = _pages[pageIndex + 1].lines.first.lineAyahs.first.ayahIndex !=
          ayahIdx;
    }
    if (isAtPageStart && pageIndex > 0) {
      // prev page last ayah != this ayah => we have a full ayah
      isFull =
          _pages[pageIndex - 1].lines.last.lineAyahs.last.ayahIndex != ayahIdx;
    }
    return (isFull, isAtPageStart, isAtPageEnd);
  }

  void _onAyahTapped(
      int surahIdx, int ayahIdx, int wordIdx, int pageNum) async {
    int currentParaIndex = widget.model.currentPara - 1;
    int absoluteAyah = toAbsoluteAyahOffset(surahIdx, ayahIdx);
    final (isFull, isAtPageStart, isAtPageEnd) =
        _isAyahFull(absoluteAyah, pageNum);

    int pageNumberOfTappedAyah = pageNum;

    void sendRepainEvent() {
      _repaintNotifier.add(pageNumberOfTappedAyah);
      if (!isFull) {
        if (isAtPageEnd) {
          _repaintNotifier.add(pageNumberOfTappedAyah + 1);
        } else if (isAtPageStart) {
          _repaintNotifier.add(pageNumberOfTappedAyah - 1);
        }
      }
    }

    List<Mutashabiha> mutashabihat = _getMutashabihaAyat(ayahIdx, surahIdx);
    Ayat? ayatInDb = _getAyatInDB(ayahIdx, surahIdx);
    if (mutashabihat.isNotEmpty) {
      // If the user clicked on a mutashabiha ayat, we show a bottom sheet

      List<Widget> widgets = [];

      if (ayatInDb != null && ayatInDb.markedWords.contains(wordIdx)) {
        widgets.add(ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete),
              Text("Remove marked word", textAlign: TextAlign.center),
            ],
          ),
          onTap: () {
            widget.model
                .removeAyats(currentParaIndex, ayatInDb.ayahIdx, wordIdx);
            Navigator.of(context).pop();
            sendRepainEvent();
          },
        ));
        // close action sheet
      } else {
        widgets.add(ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              Text("Mark word", textAlign: TextAlign.center),
            ],
          ),
          onTap: () {
            Ayat ayat = Ayat("", ayahIdx: absoluteAyah, [wordIdx]);
            widget.model.addAyahs([ayat]);
            Navigator.of(context).pop();
            sendRepainEvent();
          },
        ));
      }

      if (_quranUtf8 == null) {
        final data = await rootBundle.load("assets/quran.txt");
        _quranUtf8 = data.buffer;
      }

      for (int i = 0; i < mutashabihat.length; ++i) {
        mutashabihat[i].loadText(_quranUtf8!);
      }

      widgets.add(const Divider());
      widgets.add(ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (ctx, index) => const Divider(height: 1),
        itemCount: mutashabihat.length,
        itemBuilder: (ctx, index) {
          return MutashabihaAyatListItem(mutashabiha: mutashabihat[index]);
        },
      ));

      if (!mounted) return;

      return await showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: widgets,
              ),
            ),
          );
        },
      );
    } else {
      // otherwise we add/remove ayah
      final int abs = toAbsoluteAyahOffset(surahIdx, ayahIdx);
      if (ayatInDb != null && ayatInDb.markedWords.contains(wordIdx)) {
        // remove
        widget.model.removeAyats(currentParaIndex, abs, wordIdx);
      } else {
        // add
        Ayat ayat = Ayat("", [wordIdx], ayahIdx: abs);
        widget.model.addAyahs([ayat]);
      }
      sendRepainEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: doload(),
      builder: (context, snapshot) {
        if (_pages.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverFixedExtentList.builder(
          itemExtent: 785,
          itemCount: _pages.length,
          itemBuilder: (ctx, index) {
            return Container(
              height: 785,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 1,
                      offset: const Offset(1, 1)),
                  BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 1,
                      offset: const Offset(-1, -1))
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: PageWidget(
                  _pages[index].pageNum,
                  _pages[index].lines,
                  getAyatInDB: _getAyatInDB,
                  onAyahTapped: _onAyahTapped,
                  isMutashabihaAyat: _isMutashabihaAyat,
                  isAyahFull: _isAyahFull,
                  getFullAyahText: _getFullAyahText,
                  repaintStream: _repaintNotifier.stream,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PageWidget extends StatefulWidget {
  final int pageNum;
  final List<Line> _pageLines;
  final bool Function(int ayahIdx, int surahIdx) isMutashabihaAyat;
  final Ayat? Function(int ayahIdx, int surahIdx) getAyatInDB;
  final void Function(int surahIdx, int ayahIdx, int wordIdx, int pageIdx)
      onAyahTapped;
  final (bool, bool, bool) Function(int ayahIdx, int pageIdx) isAyahFull;
  final String Function(int ayahIdx, int pageNum) getFullAyahText;
  final Stream<int> repaintStream;

  const PageWidget(this.pageNum, this._pageLines,
      {required this.isMutashabihaAyat,
      required this.getAyatInDB,
      required this.onAyahTapped,
      required this.repaintStream,
      required this.isAyahFull,
      required this.getFullAyahText,
      super.key});

  @override
  State<StatefulWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repaintStream.listen(_triggerRepaint);
  }

  void _triggerRepaint(int page) {
    if (page == widget.pageNum) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  static String _toUrduNumber(int num) {
    final Uint16List numMap = Uint16List.fromList([
      0x6F0,
      0x6F0 + 1,
      0x6F0 + 2,
      0x6F0 + 3,
      0x6F0 + 4,
      0x6F0 + 5,
      0x6F0 + 6,
      0x6F0 + 7,
      0x6F0 + 8,
      0x6F0 + 9
    ]);
    final numStr = num.toString();
    String ret = "";
    for (final c in numStr.codeUnits) {
      ret += String.fromCharCode(numMap[c - 48]);
    }
    return ret;
  }

  void _tapHandler(int surahIdx, int ayahIdx, int wordIdx) async {
    widget.onAyahTapped(surahIdx, ayahIdx, wordIdx, widget.pageNum);
  }

  Widget getTwoLinesBismillah(int surahIdx) {
    final style = TextStyle(
      color: Colors.black,
      fontFamily: "Al Mushaf",
      fontSize: Settings.instance.fontSize.toDouble(),
      letterSpacing: 0.0,
      wordSpacing: Settings.instance.wordSpacing.toDouble(),
    );
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);

    return Column(
      textDirection: TextDirection.rtl,
      children: [
        // surah name and ayah count
        Container(
          height: 46,
          decoration:
              BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          child: Row(
            children: [
              Text(
                "\uFD3Fآیاتھا ${_toUrduNumber(surahData.ayahCount)}\uFD3E",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: style,
              ),
              const Spacer(),
              Text(
                "\uFD3Fسورۃ ${surahData.name}\uFD3E",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: style,
              ),
            ],
          ),
        ),
        // bismillah
        Container(
          height: 46,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Text(
            /*data:*/ "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
        )
      ],
    );
  }

  Widget getBismillah(int surahIdx) {
    surahIdx = -surahIdx;

    // 30th para ?
    if (widget.pageNum >= 528) {
      if (surahHas2LineHeadress(surahIdx)) {
        return getTwoLinesBismillah(surahIdx);
      }
    } else if (widget._pageLines.length == 15) {
      return getTwoLinesBismillah(surahIdx);
    }

    final style = TextStyle(
      color: Colors.black,
      fontFamily: "Al Mushaf",
      fontSize: Settings.instance.fontSize.toDouble(),
      letterSpacing: 0.0,
      wordSpacing: Settings.instance.wordSpacing.toDouble(),
    );
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration:
          BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            "\uFD3F${surahData.name}\uFD3E",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
          Text(
            /*data:*/ "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
          Text(
            "\uFD3F${_toUrduNumber(surahData.ayahCount)}\uFD3E",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }

  bool _shouldDrawAyahEndMarker(int ayahIdx, int lineIdx) {
    Line l = widget._pageLines[lineIdx];
    // If we have multiple ayahs in the line, and this not the last then this is full ayah
    if (l.lineAyahs.last.ayahIndex != ayahIdx) {
      return true;
    } else {
      bool isLast = lineIdx == widget._pageLines.length - 1;
      if (isLast) {
        return widget.isAyahFull(ayahIdx, widget.pageNum).$1;
      } else {
        if (widget._pageLines[lineIdx + 1].lineAyahs.first.ayahIndex !=
            ayahIdx) {
          return true;
        }
      }
    }
    return false;
  }

  bool isSajdaAyat(int surahIndex, int ayahIndex) {
    return switch (surahIndex) {
      6 => ayahIndex == 205,
      12 => ayahIndex == 14,
      15 => ayahIndex == 49,
      16 => ayahIndex == 108,
      18 => ayahIndex == 57,
      21 => ayahIndex == 17,
      24 => ayahIndex == 59,
      26 => ayahIndex == 25,
      31 => ayahIndex == 14,
      37 => ayahIndex == 23,
      40 => ayahIndex == 37,
      52 => ayahIndex == 61,
      83 => ayahIndex == 20,
      95 => ayahIndex == 18,
      _ => false
    };
  }

  (String marker, bool isSajda) getAyahEndMarkerGlyphCode(
      int surahIndex, int ayahIndex) {
    if (isSajdaAyat(surahIndex, ayahIndex)) {
      return (
        switch (surahIndex) {
          6 => '\uf68e',
          12 => '\uf681',
          15 => '\uf688',
          16 => '\uf68d',
          18 => '\uf689',
          21 => '\uf682',
          24 => '\uf68a',
          26 => '\uf686',
          31 => '\uf68b',
          37 => '\uf685',
          40 => '\uf687',
          52 => '\uf68c',
          83 => '\uf684',
          95 => '\uf683',
          _ => throw "Invalid sajda ayah"
        },
        true
      );
    }
    return (String.fromCharCode(0xF500 + ayahIndex), false);
  }

  // Finds the correct position of the first word of the line
  // in the full ayah text
  int getFirstWordIndex(
      List<String> fullAyahWords, List<String> currentLineWords,
      {int start = -1}) {
    String first = currentLineWords.first;
    int idx = fullAyahWords.indexOf(first, start);
    int c = 0;
    const int maxMatch = 4;
    for (int i = idx;
        i < fullAyahWords.length && c < currentLineWords.length;
        ++i, ++c) {
      String next = currentLineWords[c];
      if (fullAyahWords[i] != next) {
        return getFirstWordIndex(fullAyahWords, currentLineWords, start: i + 1);
      }
      if (c >= maxMatch) break;
    }
    return idx;
  }

  List<TextSpan> _buildLineSpans(Line line, int lineIdx) {
    List<TextSpan> spans = [];
    for (final a in line.lineAyahs) {
      final int surahIdx = surahForAyah(a.ayahIndex);
      final int surahAyahIdx = toSurahAyahOffset(surahIdx, a.ayahIndex);
      final Ayat? ayahInDb = widget.getAyatInDB(surahAyahIdx, surahIdx);
      final bool isMutashabihaAyat =
          widget.isMutashabihaAyat(surahAyahIdx, surahIdx);

      final (marker, isSajdaAyat) =
          getAyahEndMarkerGlyphCode(surahIdx, surahAyahIdx);
      String text = a.text;
      List<String> fullAyahTextWords =
          widget.getFullAyahText(a.ayahIndex, widget.pageNum).split('\u200c');
      if (isSajdaAyat) {
        text = text.replaceFirst('\u06E9', '');

        for (int i = fullAyahTextWords.length - 1; i >= 0; --i) {
          String w = fullAyahTextWords[i];
          int found = w.indexOf('\u06E9');
          if (found != -1) {
            // for whatever reason, dart is unable to replace '\u06E9' from this word
            // so manually grab substrings of before and after the marker and create
            // a new string
            String b = w.substring(0, found);
            String a = w.substring(found + 1, null);
            w = b + a;
            fullAyahTextWords[i] = w;
            break;
          }
        }
      }

      List<String> words = text.split('\u200c'); // zwj
      int i = getFirstWordIndex(fullAyahTextWords, words);

      for (final w in words) {
        int wordIdx = i;
        final tapHandler = TapGestureRecognizer()
          ..onTap = () => _tapHandler(surahIdx, surahAyahIdx, wordIdx);
        TextStyle? style;

        if (ayahInDb != null) {
          if (ayahInDb.markedWords.contains(wordIdx)) {
            style = _markedWordStyle;
          } else if (isMutashabihaAyat) {
            style = _markedMutAyahBGStyle;
          } else {
            style = _markedAyahBGStyle;
          }
        } else if (isMutashabihaAyat) {
          style = _mutStyle;
        }
        // word
        spans.add(TextSpan(recognizer: tapHandler, text: w, style: style));
        // separator
        spans.add(const TextSpan(text: '\u200c'));
        // space
        if (_shouldAddSpaces(widget.pageNum, lineIdx)) {
          spans.add(const TextSpan(text: ' '));
        }
        i++;
      }

      if (_shouldDrawAyahEndMarker(a.ayahIndex, lineIdx)) {
        bool hasRukuMarker = a.text.lastIndexOf("\uE022") != -1;
        spans.add(
          TextSpan(
            text: marker,
            style: TextStyle(
              color: Colors.black,
              backgroundColor: hasRukuMarker ? Colors.amber.shade100 : null,
              fontFamily: "AyahNumber",
              fontSize: 24,
            ),
          ),
        );
      }
    }
    return spans;
  }

  Widget _buildLine(Line line, int lineIdx) {
    return Text.rich(
      TextSpan(children: _buildLineSpans(line, lineIdx)),
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: "Al Mushaf",
        fontSize: 24,
        letterSpacing: 0,
        wordSpacing: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          (widget.pageNum + 1).toString(),
          style: const TextStyle(fontSize: 12),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              separatorBuilder: (ctx, idx) => const Divider(
                color: Colors.grey,
                height: 1,
              ),
              itemCount: widget._pageLines.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, idx) {
                final pageLine = widget._pageLines[idx];
                if (pageLine.lineAyahs.first.ayahIndex < 0) {
                  return getBismillah(pageLine.lineAyahs.first.ayahIndex);
                }

                return SizedBox(
                  height: 46,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _buildLine(pageLine, idx),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
