{ $OmniXML: OmniXML/OmniXML_LookupTables.pas,v 1.1.1.1 2004/04/17 11:16:33 mr Exp $ }

(*******************************************************************************
* The contents of this file are subject to the Mozilla Public License Version  *
* 1.1 (the "License"); you may not use this file except in compliance with the *
* License. You may obtain a copy of the License at http://www.mozilla.org/MPL/ *
*                                                                              *
* Software distributed under the License is distributed on an "AS IS" basis,   *
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for *
* the specific language governing rights and limitations under the License.    *
*                                                                              *
* The Original Code is OmniXML_LookupTables.pas                                *
*                                                                              *
* The Initial Developer of the Original Code is Miha Remec                     *
*   http://www.MihaRemec.com/                                                  *
*                                                                              *
* Contributor(s): Erik Berry <eb@techie.com>                                   *
*******************************************************************************)
unit OmniXML_LookupTables;

interface

var
  XMLCharLookupTable: array of Byte;

implementation

type
  TRLEItem = record
    Val: Byte;
    Len: Smallint;
  end;

const RLEArray: array [0..612] of TRLEItem = (
  (Val: $00; Len: 9;),
  (Val: $40; Len: 2;),
  (Val: $00; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $00; Len: 18;),
  (Val: $40; Len: 13;),
  (Val: $C0; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $C4; Len: 10;),
  (Val: $C0; Len: 1;),
  (Val: $40; Len: 6;),
  (Val: $D1; Len: 26;),
  (Val: $40; Len: 4;),
  (Val: $C0; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 26;),
  (Val: $40; Len: 60;),
  (Val: $E0; Len: 1;),
  (Val: $40; Len: 8;),
  (Val: $D1; Len: 23;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 31;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 58;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 11;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 53;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 68;),
  (Val: $40; Len: 9;),
  (Val: $D1; Len: 36;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 30;),
  (Val: $40; Len: 56;),
  (Val: $D1; Len: 89;),
  (Val: $40; Len: 18;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 14;),
  (Val: $E0; Len: 2;),
  (Val: $40; Len: 46;),
  (Val: $C2; Len: 70;),
  (Val: $40; Len: 26;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 36;),
  (Val: $D1; Len: 1;),
  (Val: $E0; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 20;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 44;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 18;),
  (Val: $40; Len: 13;),
  (Val: $D1; Len: 12;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 66;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 12;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 36;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 9;),
  (Val: $D1; Len: 53;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 28;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 55;),
  (Val: $D1; Len: 38;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 7;),
  (Val: $D1; Len: 38;),
  (Val: $40; Len: 10;),
  (Val: $C2; Len: 17;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 23;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 11;),
  (Val: $D1; Len: 27;),
  (Val: $40; Len: 5;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 46;),
  (Val: $D1; Len: 26;),
  (Val: $40; Len: 5;),
  (Val: $E0; Len: 1;),
  (Val: $D1; Len: 10;),
  (Val: $C2; Len: 8;),
  (Val: $40; Len: 13;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 6;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 71;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 15;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 15;),
  (Val: $D1; Len: 2;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 2;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 519;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 53;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 16;),
  (Val: $40; Len: 3;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 10;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 17;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 22;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 7;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 9;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C4; Len: 10;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 16;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 6;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 22;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 5;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 11;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 7;),
  (Val: $C4; Len: 10;),
  (Val: $C2; Len: 2;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 12;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 22;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 18;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 5;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 17;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 22;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 3;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 8;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 4;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 18;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 6;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 5;),
  (Val: $40; Len: 3;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 9;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 15;),
  (Val: $C4; Len: 9;),
  (Val: $40; Len: 17;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 23;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 10;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 7;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 9;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 4;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 18;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 23;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 10;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 7;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 7;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 4;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 18;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 23;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 16;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 2;),
  (Val: $C2; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 4;),
  (Val: $40; Len: 9;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 8;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 4;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 145;),
  (Val: $D1; Len: 46;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $C2; Len: 7;),
  (Val: $40; Len: 5;),
  (Val: $D1; Len: 6;),
  (Val: $E0; Len: 1;),
  (Val: $C2; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 39;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 6;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 2;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 1;),
  (Val: $E0; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 2;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 62;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 6;),
  (Val: $C4; Len: 10;),
  (Val: $40; Len: 11;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 2;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 33;),
  (Val: $40; Len: 7;),
  (Val: $C2; Len: 20;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 21;),
  (Val: $40; Len: 3;),
  (Val: $C2; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 230;),
  (Val: $D1; Len: 38;),
  (Val: $40; Len: 10;),
  (Val: $D1; Len: 39;),
  (Val: $40; Len: 9;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 5;),
  (Val: $40; Len: 41;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 11;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 5;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 40;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 9;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 7;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 40;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 8;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3078;),
  (Val: $D1; Len: 156;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 90;),
  (Val: $40; Len: 6;),
  (Val: $D1; Len: 22;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 6;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 38;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 6;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 8;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 31;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 53;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 4;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 6;),
  (Val: $40; Len: 4;),
  (Val: $D1; Len: 13;),
  (Val: $40; Len: 5;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 1;),
  (Val: $D1; Len: 7;),
  (Val: $40; Len: 211;),
  (Val: $C2; Len: 13;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 1;),
  (Val: $40; Len: 68;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 3;),
  (Val: $D1; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 1;),
  (Val: $40; Len: 81;),
  (Val: $D1; Len: 3;),
  (Val: $40; Len: 3714;),
  (Val: $E0; Len: 1;),
  (Val: $40; Len: 1;),
  (Val: $D8; Len: 1;),
  (Val: $40; Len: 25;),
  (Val: $D8; Len: 9;),
  (Val: $C2; Len: 6;),
  (Val: $40; Len: 1;),
  (Val: $E0; Len: 5;),
  (Val: $40; Len: 11;),
  (Val: $D1; Len: 84;),
  (Val: $40; Len: 4;),
  (Val: $C2; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $E0; Len: 2;),
  (Val: $40; Len: 2;),
  (Val: $D1; Len: 90;),
  (Val: $40; Len: 1;),
  (Val: $E0; Len: 3;),
  (Val: $40; Len: 6;),
  (Val: $D1; Len: 40;),
  (Val: $40; Len: 7379;),
  (Val: $D8; Len: 20902;),
  (Val: $40; Len: 3162;),
  (Val: $D1; Len: 11172;),
  (Val: $40; Len: 92;),
  (Val: $00; Len: 2048;),
  (Val: $40; Len: 8190;)
);

procedure InitializeCharLookupTable;
var
  i, j: Integer;
  Value: Byte;
  Length: Smallint;
  TablePos: Integer;
begin
  SetLength(XMLCharLookupTable, 65536);
  TablePos := 0;
  for i := Low(RLEArray) to High(RLEArray) do
  begin
    Value := RLEArray[i].Val;
    Length := RLEArray[i].Len;
    for j := 0 to Length - 1 do
    begin
      XMLCharLookupTable[TablePos] := Value;
      Inc(TablePos);
    end;
  end;
end;

initialization
  InitializeCharLookupTable;

end.