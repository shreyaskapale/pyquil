grammar Quil;

////////////////////
// PARSER
////////////////////

quil                : allInstr? ( NEWLINE+ allInstr )* NEWLINE* EOF ;

allInstr            : defGate
                    | defCircuit
                    | defWaveform
                    | defCalibration
                    | defMeasCalibration
                    | instr
                    ;

instr               : fence
                    | delay
                    | gate
                    | measure
                    | defLabel
                    | halt
                    | jump
                    | jumpWhen
                    | jumpUnless
                    | resetState
                    | wait
                    | classicalUnary
                    | classicalBinary
                    | classicalComparison
                    | load
                    | store
                    | nop
                    | include
                    | pragma
                    | pulse
                    | setFrequency
                    | setPhase
                    | shiftPhase
                    | swapPhases
                    | setScale
                    | capture
                    | rawCapture
                    | memoryDescriptor // this is a little unusual, but it's in steven's example
                    ;

// C. Static and Parametric Gates

gate                : modifier* name ( LPAREN param ( COMMA param )* RPAREN )? qubit+ ;

name                : IDENTIFIER ;
qubit               : INT ;

param               : expression ;

modifier            : CONTROLLED
                    | DAGGER ;

// D. Gate Definitions

defGate             : DEFGATE name (( LPAREN variable ( COMMA variable )* RPAREN ) | ( AS gatetype ))? COLON NEWLINE matrix ;

variable            : PERCENTAGE IDENTIFIER ;
gatetype            : MATRIX
                    | PERMUTATION ;

matrix              : ( matrixRow NEWLINE )* matrixRow ;
matrixRow           : TAB expression ( COMMA expression )* ;

// E. Circuits

defCircuit          : DEFCIRCUIT name ( LPAREN variable ( COMMA variable )* RPAREN )? qubitVariable* COLON NEWLINE circuit ;

qubitVariable       : IDENTIFIER ;

circuitQubit        : qubit | qubitVariable ;
circuitGate         : name ( LPAREN param ( COMMA param )* RPAREN )? circuitQubit+ ;
circuitMeasure      : MEASURE circuitQubit addr? ;
circuitResetState   : RESET circuitQubit? ;
circuitInstr        : circuitGate | circuitMeasure | circuitResetState | instr ;
circuit             : ( TAB circuitInstr NEWLINE )* TAB circuitInstr ;

// F. Measurement

measure             : MEASURE qubit addr? ;
addr                : IDENTIFIER | ( IDENTIFIER? LBRACKET INT RBRACKET );

// G. Program control

defLabel            : LABEL label ;
label               : AT IDENTIFIER ;
halt                : HALT ;
jump                : JUMP label ;
jumpWhen            : JUMPWHEN label addr ;
jumpUnless          : JUMPUNLESS label addr ;

// H. Zeroing the Quantum State

resetState          : RESET qubit? ; // NB: cannot be named "reset" due to conflict with Antlr implementation

// I. Classical/Quantum Synchronization

wait                : WAIT ;

// J. Classical Instructions

memoryDescriptor    : DECLARE IDENTIFIER IDENTIFIER ( LBRACKET INT RBRACKET )? ( SHARING IDENTIFIER ( offsetDescriptor )* )? ;
offsetDescriptor    : OFFSET INT IDENTIFIER ;

classicalUnary      : ( NEG | NOT | TRUE | FALSE ) addr ;
classicalBinary     : logicalBinaryOp | arithmeticBinaryOp | move | exchange | convert ;
logicalBinaryOp     : ( AND | OR | IOR | XOR ) addr ( addr | INT ) ;
arithmeticBinaryOp  : ( ADD | SUB | MUL | DIV ) addr ( addr | number ) ;
move                : MOVE addr ( addr | number );
exchange            : EXCHANGE addr addr ;
convert             : CONVERT addr addr ;
load                : LOAD addr IDENTIFIER addr ;
store               : STORE IDENTIFIER addr ( addr | number );
classicalComparison : ( EQ | GT | GE | LT | LE ) addr addr ( addr | number );

// K. The No-Operation Instruction

nop                 : NOP ;

// L. File Inclusion

include             : INCLUDE STRING ;

// M. Pragma Support

pragma              : PRAGMA IDENTIFIER pragma_name* STRING? ;
pragma_name         : IDENTIFIER | INT ;

// Expressions (in order of precedence)

expression          : LPAREN expression RPAREN                  #parenthesisExp
                    | sign expression                           #signedExp
                    | <assoc=right> expression POWER expression #powerExp
                    | expression ( TIMES | DIVIDE ) expression  #mulDivExp
                    | expression ( PLUS | MINUS ) expression    #addSubExp
                    | function LPAREN expression RPAREN         #functionExp
                    | number                                    #numberExp
                    | variable                                  #variableExp
                    | addr                                      #addrExp
                    ;

function            : SIN | COS | SQRT | EXP | CIS ;
sign                : PLUS | MINUS ;

// Numbers
// We suffix -N onto these names so they don't conflict with already defined Python types

number              : MINUS? ( realN | imaginaryN | I | PI ) ;
imaginaryN          : realN I ;
realN               : FLOAT | INT ;

// Analog control

defWaveform         : DEFWAVEFORM name ( LPAREN param (COMMA param)* RPAREN )? COLON NEWLINE matrix ;
pulse               : PULSE formalQubit+ frame waveform ;
setFrequency        : SETFREQUENCY formalQubit+ frame expression ;
setPhase            : SETPHASE formalQubit+ frame expression ;
shiftPhase          : SHIFTPHASE formalQubit+ frame expression ;
swapPhases          : SWAPPHASES formalQubit+ frame qubit+ frame ;
setScale            : SETSCALE formalQubit+ frame expression ;
capture             : CAPTURE formalQubit frame waveform addr ;
rawCapture          : RAWCAPTURE formalQubit+ frame expression addr ;
defCalibration      : DEFCAL name (LPAREN param ( COMMA param )* RPAREN)? formalQubit+ COLON ( NEWLINE TAB instr )* ;
defMeasCalibration  : DEFCAL MEASURE formalQubit addr COLON ( NEWLINE TAB instr )* ;
delay               : DELAY formalQubit expression ;
fence               : FENCE formalQubit+ ;

formalQubit         : qubit | qubitVariable ;
namedParam          : colonTerminatedName expression ;
frame               : STRING ;
waveform            : name (LPAREN namedParam ( COMMA namedParam )* RPAREN)? ;
colonTerminatedName : COLONTERMIDENT ;
// built-in waveform types include: "flat", "gaussian", "draggaussian", "erfsquare"
// TODO: parameters might be named.


////////////////////
// LEXER
////////////////////

// Keywords

DEFGATE             : 'DEFGATE' ;
DEFCIRCUIT          : 'DEFCIRCUIT' ;
MEASURE             : 'MEASURE' ;

LABEL               : 'LABEL' ;
HALT                : 'HALT' ;
JUMP                : 'JUMP' ;
JUMPWHEN            : 'JUMP-WHEN' ;
JUMPUNLESS          : 'JUMP-UNLESS' ;

RESET               : 'RESET' ;
WAIT                : 'WAIT' ;
NOP                 : 'NOP' ;
INCLUDE             : 'INCLUDE' ;
PRAGMA              : 'PRAGMA' ;

DECLARE             : 'DECLARE' ;
SHARING             : 'SHARING' ;
OFFSET              : 'OFFSET' ;

AS                  : 'AS' ;
MATRIX              : 'MATRIX' ;
PERMUTATION         : 'PERMUTATION' ;

NEG                 : 'NEG' ;
NOT                 : 'NOT' ;
TRUE                : 'TRUE' ; // Deprecated
FALSE               : 'FALSE' ; // Deprecated

AND                 : 'AND' ;
IOR                 : 'IOR' ;
XOR                 : 'XOR' ;
OR                  : 'OR' ;   // Deprecated

ADD                 : 'ADD' ;
SUB                 : 'SUB' ;
MUL                 : 'MUL' ;
DIV                 : 'DIV' ;

MOVE                : 'MOVE' ;
EXCHANGE            : 'EXCHANGE' ;
CONVERT             : 'CONVERT' ;

EQ                  : 'EQ';
GT                  : 'GT';
GE                  : 'GE';
LT                  : 'LT';
LE                  : 'LE';

LOAD                : 'LOAD' ;
STORE               : 'STORE' ;

PI                  : 'pi' ;
I                   : 'i' ;

SIN                 : 'SIN' ;
COS                 : 'COS' ;
SQRT                : 'SQRT' ;
EXP                 : 'EXP' ;
CIS                 : 'CIS' ;

// Operators

PLUS                : '+' ;
MINUS               : '-' ;
TIMES               : '*' ;
DIVIDE              : '/' ;
POWER               : '^' ;

// analog keywords

DEFWAVEFORM         : 'DEFWAVEFORM' ;
PULSE               : 'PULSE ';
SETFREQUENCY        : 'SET-FREQUENCY' ;
SETPHASE            : 'SET-PHASE' ;
SHIFTPHASE          : 'SHIFT-PHASE' ;
SWAPPHASES          : 'SWAP-PHASES' ;
SETSCALE            : 'SET-SCALE' ;
CAPTURE             : 'CAPTURE' ;
RAWCAPTURE          : 'RAW-CAPTURE' ;
DEFCAL              : 'DEFCAL' ;
DELAY               : 'DELAY' ;
FENCE               : 'FENCE' ;

// Modifiers

CONTROLLED          : 'CONTROLLED' ;
DAGGER              : 'DAGGER' ;

// Identifiers

IDENTIFIER          : ( ( [A-Za-z_] ) | ( [A-Za-z_] [A-Za-z0-9\-_]* [A-Za-z0-9_] ) ) ;
COLONTERMIDENT      : IDENTIFIER ':' ;

// Numbers

INT                 : [0-9]+ ;
FLOAT               : [0-9]+ ( '.' [0-9]+ )? ( ( 'e'|'E' ) ( '+' | '-' )? [0-9]+ )? ;

// String

STRING              : '"' ~( '\n' | '\r' )* '"';

// Punctuation

PERIOD              : '.' ;
COMMA               : ',' ;
LPAREN              : '(' ;
RPAREN              : ')' ;
LBRACKET            : '[' ;
RBRACKET            : ']' ;
COLON               : ':' ;
PERCENTAGE          : '%' ;
AT                  : '@' ;
QUOTE               : '"' ;
UNDERSCORE          : '_' ;

// Whitespace

TAB                 : '    ' ;
NEWLINE             : (' ' | '\t' )* ( '\r'? '\n' | '\r' )+ ;

// Skips

COMMENT             : (' ' | '\t' )* '#' ~( '\n' | '\r' )* -> skip ;
SPACE               : ' ' -> skip ;

// Error

INVALID             : . ;
