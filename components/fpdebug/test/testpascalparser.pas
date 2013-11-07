unit TestPascalParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, FpPascalParser, LazLogger;

type

  { TTestPascalParser }

  TTestPascalParser = class(TTestCase)
  published
    procedure TestParser;
  end;

implementation


type

  { TTestFpPascalExpression }

  TTestFpPascalExpression=class(TFpPascalExpression)
  public
    property ExpressionPart;
  end;

{ TTestFpPascalExpression }

procedure TTestPascalParser.TestParser;
var
  CurrentTestExprText: String;
  CurrentTestExprObj: TTestFpPascalExpression;

  function GetChild(p: TFpPascalExpressionPart; i: array of integer): TFpPascalExpressionPart;
  var
    j: Integer;
  begin
    Result := p;
    for j := low(i) to high(i) do
      Result := (Result as TFpPascalExpressionPartContainer).Items[i[j]];
  end;

  function GetChild(i: array of integer): TFpPascalExpressionPart;
  begin
    Result := GetChild(CurrentTestExprObj.ExpressionPart, i);
  end;

  Procedure TestExpr(APart: TFpPascalExpressionPart; AClass: TFpPascalExpressionPartClass;
    AText: String; AChildCount: Integer = -1);
  begin
    AssertNotNull(CurrentTestExprText+ ': IsAssigned', APart);
    AssertTrue(CurrentTestExprText+': APart IS Class exp: '+AClass.ClassName+' was: '+APart.ClassName,
               APart is AClass);
    AssertEquals(CurrentTestExprText+': Text', AText, APart.GetText);
    if AChildCount >=0 then begin
      AssertTrue(CurrentTestExprText+': Is container ', APart is TFpPascalExpressionPartContainer);
      AssertEquals(CurrentTestExprText+': childcount ', AChildCount, (APart as TFpPascalExpressionPartContainer).Count);
    end;
  end;

  Procedure TestExpr(i: array of integer; AClass: TFpPascalExpressionPartClass;
    AText: String; AChildCount: Integer = -1);
  begin
    TestExpr(GetChild(i), AClass, AText, AChildCount);
  end;

  procedure CreateExpr(t: string; ExpValid: Boolean);
  begin
    FreeAndNil(CurrentTestExprObj);
    CurrentTestExprText := t;
    CurrentTestExprObj := TTestFpPascalExpression.Create(CurrentTestExprText);
DebugLn(CurrentTestExprObj.DebugDump);
    AssertEquals('Valid '+CurrentTestExprObj.Error+ ' # '+CurrentTestExprText, ExpValid, CurrentTestExprObj.Valid);
  end;

begin
  CurrentTestExprObj := nil;
  try
    CreateExpr('a', True);
    TestExpr([], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('a b', False);
    CreateExpr('a |', False);
    CreateExpr('| b', False);
    CreateExpr('|', False);

    CreateExpr('@a', True);
    TestExpr([], TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('a@', False);
    CreateExpr('@', False);

    CreateExpr('-a', True);
    TestExpr([], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('+-a', True);
    TestExpr([], TFpPascalExpressionPartOperatorUnaryPlusMinus, '+', 1);
    TestExpr([0], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('a+b', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1], TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('a+', False);
    CreateExpr('a*', False);
    CreateExpr('a+b-', False);
    CreateExpr('a@+b', False);

    CreateExpr('a+-b', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([1,0], TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('+a + -@b  -  @+c', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '-', 2);
    TestExpr(       [0],       TFpPascalExpressionPartOperatorPlusMinus,    '+', 2);
      TestExpr(     [0,0],     TFpPascalExpressionPartOperatorUnaryPlusMinus,'+', 1);
        TestExpr(   [0,0,0],   TFpPascalExpressionPartIdentifer,              'a', 0);
      TestExpr(     [0,1],     TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
        TestExpr(   [0,1,0],   TFpPascalExpressionPartOperatorAddressOf,       '@', 1);
          TestExpr([0,1,0,0], TFpPascalExpressionPartIdentifer,                'b', 0);
    TestExpr(       [1],       TFpPascalExpressionPartOperatorAddressOf,     '@', 1);
      TestExpr(     [1,0],     TFpPascalExpressionPartOperatorUnaryPlusMinus, '+', 1);
        TestExpr(   [1,0,0],   TFpPascalExpressionPartIdentifer,               'c', 0);

    CreateExpr('a+b*c', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
    TestExpr([1,0], TFpPascalExpressionPartIdentifer, 'b', 0);
    TestExpr([1,1], TFpPascalExpressionPartIdentifer, 'c', 0);

    CreateExpr('a*b+c', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr(   [0], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
      TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);
      TestExpr([0,1], TFpPascalExpressionPartIdentifer, 'b', 0);
    TestExpr(   [1], TFpPascalExpressionPartIdentifer, 'c', 0);

    CreateExpr('a*b+c*d', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr(   [0], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
      TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);
      TestExpr([0,1], TFpPascalExpressionPartIdentifer, 'b', 0);
    TestExpr(   [1], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
      TestExpr([1,0], TFpPascalExpressionPartIdentifer, 'c', 0);
      TestExpr([1,1], TFpPascalExpressionPartIdentifer, 'd', 0);

    CreateExpr('@a*@b+@c', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus,                       '+', 2);
    TestExpr(     [0],     TFpPascalExpressionPartOperatorMulDiv,    '*', 2);
      TestExpr(   [0,0],   TFpPascalExpressionPartOperatorAddressOf,  '@', 1);
        TestExpr([0,0,0], TFpPascalExpressionPartIdentifer,           'a', 0);
      TestExpr(   [0,1],   TFpPascalExpressionPartOperatorAddressOf,  '@', 1);
        TestExpr([0,1,0], TFpPascalExpressionPartIdentifer,           'b', 0);
    TestExpr(     [1],     TFpPascalExpressionPartOperatorAddressOf, '@', 1);
      TestExpr(   [1,0],   TFpPascalExpressionPartIdentifer,          'c', 0);

    CreateExpr('@a*@b+@c*@d', True);
    TestExpr([], TFpPascalExpressionPartOperatorPlusMinus,                       '+', 2);
    TestExpr(     [0],     TFpPascalExpressionPartOperatorMulDiv,    '*', 2);
      TestExpr(   [0,0],   TFpPascalExpressionPartOperatorAddressOf,  '@', 1);
        TestExpr([0,0,0], TFpPascalExpressionPartIdentifer,           'a', 0);
      TestExpr(   [0,1],   TFpPascalExpressionPartOperatorAddressOf,  '@', 1);
        TestExpr([0,1,0], TFpPascalExpressionPartIdentifer,           'b', 0);
    TestExpr(     [1],     TFpPascalExpressionPartOperatorMulDiv,    '*', 2);
      TestExpr(   [1,0],     TFpPascalExpressionPartOperatorAddressOf, '@', 1);
        TestExpr([1,0,0],   TFpPascalExpressionPartIdentifer,          'c', 0);
      TestExpr(   [1,1],     TFpPascalExpressionPartOperatorAddressOf, '@', 1);
        TestExpr([1,1,0],   TFpPascalExpressionPartIdentifer,          'd', 0);


    CreateExpr('a.b', True);
    TestExpr([], TFpPascalExpressionPartOperatorMemberOf,  '.', 2);
    TestExpr([0], TFpPascalExpressionPartIdentifer,        'a', 0);
    TestExpr([1], TFpPascalExpressionPartIdentifer,        'b', 0);

    CreateExpr('a.b^', True);
    TestExpr([], TFpPascalExpressionPartOperatorDeRef,  '^', 1);
    TestExpr([0], TFpPascalExpressionPartOperatorMemberOf,  '.', 2);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer,        'a', 0);
    TestExpr([0,1], TFpPascalExpressionPartIdentifer,        'b', 0);

    CreateExpr('a^.b', True);
    TestExpr([], TFpPascalExpressionPartOperatorMemberOf,  '.', 2);
    TestExpr([0], TFpPascalExpressionPartOperatorDeRef,  '^', 1);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer,        'a', 0);
    TestExpr([1], TFpPascalExpressionPartIdentifer,        'b', 0);

    CreateExpr('a.b.c', True);
    TestExpr([], TFpPascalExpressionPartOperatorMemberOf,  '.', 2);
    TestExpr([0], TFpPascalExpressionPartOperatorMemberOf,  '.', 2);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer,        'a', 0);
    TestExpr([0,1], TFpPascalExpressionPartIdentifer,        'b', 0);
    TestExpr([1], TFpPascalExpressionPartIdentifer,        'c', 0);

    CreateExpr('(a)', True);
    TestExpr([], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('a)', False);
    CreateExpr('(a', False);
    CreateExpr(')', False);
    CreateExpr('(', False);
    CreateExpr('(*a)', False);

    CreateExpr('(-a)', True);
    TestExpr([], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('-(-a)', True);
    TestExpr([], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0,0], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0,0,0], TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('(a*b)', True);
    TestExpr([], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([0,1], TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('(-a*b)', True);
    TestExpr([], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
    TestExpr([0,0], TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0,0,0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([0,1], TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('(a)*b', True);
    TestExpr([], TFpPascalExpressionPartOperatorMulDiv, '*', 2);
    TestExpr([0], TFpPascalExpressionPartBracketSubExpression, '(', 1);
    TestExpr([0,0], TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1], TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('(a+b)*c', True);
    CreateExpr('(@a)*@c', True);
    CreateExpr('(@a+@b)*@c', True);

    CreateExpr('f(a+b)*c', True);
    TestExpr(     [],      TFpPascalExpressionPartOperatorMulDiv, '*', 2);
    TestExpr(     [0],     TFpPascalExpressionPartBracketArgumentList, '(', 2);
      TestExpr(   [0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
      TestExpr(   [0,1],   TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
        TestExpr([0,1,0], TFpPascalExpressionPartIdentifer, 'a', 0);
        TestExpr([0,1,1], TFpPascalExpressionPartIdentifer, 'b', 0);
    TestExpr(     [1],     TFpPascalExpressionPartIdentifer, 'c', 0);

    CreateExpr('f(a)', True);
    TestExpr([],    TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('f(a)(b)', True);
    TestExpr([],    TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0],     TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],     TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],     TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1],     TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('f()', True);
    TestExpr([],    TFpPascalExpressionPartBracketArgumentList, '(', 1);
    TestExpr([0],     TFpPascalExpressionPartIdentifer, 'f', 0);

    CreateExpr('f(a)+b', True);
    TestExpr([],  TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('c+f(a)', True);
    TestExpr([],  TFpPascalExpressionPartOperatorPlusMinus, '+', 2);
    TestExpr([0],   TFpPascalExpressionPartIdentifer, 'c', 0);
    TestExpr([1],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([1,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([1,1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('c.f(a)', True);  // (c.f) (a)
    TestExpr([],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0],   TFpPascalExpressionPartOperatorMemberOf, '.', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'c', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('f(a).c', True);  // (c.f) (a)
    TestExpr([],   TFpPascalExpressionPartOperatorMemberOf, '.', 2);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'c', 0);

    CreateExpr('@f(a)', True);   // @( f(a) )
    TestExpr([],  TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('-f(a)', True);   // -( f(a) )
    TestExpr([],  TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('f^(a)', True);   // (f^) (a)
    TestExpr([],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('f(a)^', True);   // ( f(a) )^
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('f(a)(b)^', True);   // ( f(a)(b) )^
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],   TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('f.()', False);
    CreateExpr('f(*a)', False);

    CreateExpr('f[a]', True);
    CreateExpr('f * [a]', True);

    CreateExpr('a^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('-a^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('@a^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0],  TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('-@a', True);
    TestExpr([],  TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0],  TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('-@a^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorUnaryPlusMinus, '-', 1);
    TestExpr([0],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0,0],  TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0,0,0],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('^f(a)', True);
    TestExpr([], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0],  TFpPascalExpressionPartOperatorMakeRef, '^', 1);
    TestExpr([0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('^f(a)^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0],  TFpPascalExpressionPartOperatorMakeRef, '^', 1);
    TestExpr([0,0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);

    CreateExpr('@f(a)(b)', True);
    TestExpr([],  TFpPascalExpressionPartOperatorAddressOf, '@', 1);
    TestExpr([0], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'b', 0);

    CreateExpr('f(a)(b)^', True);
    TestExpr([],  TFpPascalExpressionPartOperatorDeRef, '^', 1);
    TestExpr([0], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0], TFpPascalExpressionPartBracketArgumentList, '(', 2);
    TestExpr([0,0,0],   TFpPascalExpressionPartIdentifer, 'f', 0);
    TestExpr([0,0,1],   TFpPascalExpressionPartIdentifer, 'a', 0);
    TestExpr([0,1],   TFpPascalExpressionPartIdentifer, 'b', 0);

  finally
    CurrentTestExprObj.Free;
  end;
end;



initialization

  RegisterTest(TTestPascalParser);
end.
