%%-------------------------------------------------------------------------------------------
%% Copyright (c) 2021 Venkatakumar Srinivasan
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% @author Venkatakumar Srinivasan
%% @since February 06, 2021
%%
%%-------------------------------------------------------------------------------------------
-module(ebase58).

%% API exports
-export([
         encode/1,
         decode/1
]).

%%====================================================================
%% API functions
%%====================================================================
-spec encode(binary() | integer()) -> binary().
encode(Data) when is_integer(Data) ->
  encode( binary:encode_unsigned(Data) );

encode(Data) when is_binary(Data) ->
  {ZeroCount, Bin} = zeros(0, Data),
  BigInt = binary:decode_unsigned(Bin),
  Encoded = encode(BigInt, []),
  Prefix = [$1 || <<_>> <= <<0:(ZeroCount*8)>>],
  iolist_to_binary([Prefix, Encoded]);

encode(_) ->
  erlang:error(badarg).

-spec decode(binary()) -> binary() | {error, term()}.
decode(<<>>) ->
  <<>>;

decode(Data) when is_binary(Data) ->
  try
    {Ones, Bin} = ones(0, Data),
    Decoded = binary:encode_unsigned(decode_to_unsigned(Bin)),
    Prefix = <<0:(Ones*8)>>,
    iolist_to_binary([Prefix, Decoded])
  catch
    _ : Reason ->
      {error, Reason}
  end;

decode(_) ->
  erlang:error(badarg).


%%====================================================================
%% Internal functions
%%====================================================================
zeros(Count, <<0:8, Rest/binary>>) ->
  zeros(Count+1, Rest);

zeros(Count, Rest) ->
  {Count, Rest}.

ones(Count, <<$1:8, Rest/binary>>) ->
  ones(Count+1, Rest);

ones(Count, Rest) ->
  {Count, Rest}.

encode(BigInt, Encoded) when BigInt > 0 ->
  Output = enc(BigInt rem 58),
  encode(BigInt div 58, [Output|Encoded]);

encode(0, Encoded) ->
  Encoded.

decode_to_unsigned(Bin) ->
  <<I:8, Rest/binary>> = Bin,
  to_unsigned(Rest, dec(I)).

to_unsigned(<<>>, Carry) ->
  Carry;

to_unsigned(<<I:8, Rest/binary>>, Carry) ->
  to_unsigned(Rest, Carry * 58 + dec(I)).

enc(Val) when (Val >= 0), (Val < 9) ->
  $1 + Val;

enc(Val) when Val >= 9, Val < 17 ->
  $A + (Val - 9);

enc(Val) when Val >= 17, Val < 22 ->
  $J + (Val - 17);

enc(Val) when Val >= 22, Val < 33 ->
  $P + (Val - 22);

enc(Val) when Val >= 33, Val < 44 ->
  $a + (Val - 33);

enc(Val) when Val >= 44, Val < 58 ->
  $m + (Val - 44).

dec(Val) when (Val >= $1), (Val =< $9) ->
  Val - $1;

dec(Val) when Val >= $A, Val =< $H ->
  (Val - $A) + 9;

dec(Val) when Val >= $J, Val =< $N ->
  (Val - $J) + 17;

dec(Val) when Val >= $P, Val =< $Z ->
  (Val - $P) + 22;

dec(Val) when Val >= $a, Val =< $k ->
  (Val - $a) + 33;

dec(Val) when Val >= $m, Val =< $z ->
  (Val - $m) + 44;
dec(_) ->
  erlang:throw(invalid_base58_input).




%%=========================================================================
%% Unit Test Suite
%%=========================================================================
-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-define(BIN(X), binary:encode_unsigned(X)).
encode_suite_test_() ->
  [
   ?_assertMatch(<<>>, ebase58:encode(<<"">>)),
   ?_assertMatch(<<"2NEpo7TZRRrLZSi2U">>, ebase58:encode(<<"Hello World!">>)),
   ?_assertMatch(<<"USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z">>, ebase58:encode(<<"The quick brown fox jumps over the lazy dog.">>)),
   ?_assertMatch(<<"233QC4">>, ebase58:encode(16#0000287fb4cd)),
   ?_assertMatch(<<"11233QC4">>, ebase58:encode(<<0, 0, 40, 127, 180, 205>>)),
   ?_assertMatch(<<"6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM">>, ebase58:encode(25420294593250030202636073700053352635053786165627414518)),
   ?_assertMatch(<<"2g">>, ebase58:encode(16#61)),
   ?_assertMatch(<<"a3gV">>, ebase58:encode(16#626262)),
   ?_assertMatch(<<"aPEr">>, ebase58:encode(16#636363)),
   ?_assertMatch(<<"2cFupjhnEsSn59qHXstmK2ffpLv2">>, ebase58:encode(16#73696d706c792061206c6f6e6720737472696e67)),
   ?_assertMatch(<<"ABnLTmg">>, ebase58:encode(16#516b6fcd0f)),
   ?_assertMatch(<<"3SEo3LWLoPntC">>, ebase58:encode(16#bf4f89001e670274dd)),
   ?_assertMatch(<<"3EFU7m">>, ebase58:encode(16#572e4794)),
   ?_assertMatch(<<"EJDM8drfXA6uyA">>, ebase58:encode(16#ecac89cad93923c02321)),
   ?_assertMatch(<<"Rt5zm">>, ebase58:encode(16#10c8511e))
  ].

decode_suite_test_() ->
  [
   ?_assertEqual(<<"Hello World!">>, ebase58:decode(<<"2NEpo7TZRRrLZSi2U">>)),
   ?_assertEqual(<<"The quick brown fox jumps over the lazy dog.">>, ebase58:decode(<<"USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z">>)),
   ?_assertEqual(<<0, 0, 40, 127, 180, 205>>, ebase58:decode(<<"11233QC4">>)),
   ?_assertEqual(?BIN(16#0000287fb4cd), ebase58:decode(<<"233QC4">>)),
   ?_assertEqual(?BIN(25420294593250030202636073700053352635053786165627414518), ebase58:decode(<<"6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM">>)),
   ?_assertEqual(?BIN(16#61), ebase58:decode(<<"2g">>)),
   ?_assertEqual(?BIN(16#626262), ebase58:decode(<<"a3gV">>)),
   ?_assertEqual(?BIN(16#636363), ebase58:decode(<<"aPEr">>)),
   ?_assertEqual(?BIN(16#73696d706c792061206c6f6e6720737472696e67), ebase58:decode(<<"2cFupjhnEsSn59qHXstmK2ffpLv2">>)),
   ?_assertEqual(?BIN(16#516b6fcd0f), ebase58:decode(<<"ABnLTmg">>)),
   ?_assertEqual(?BIN(16#bf4f89001e670274dd), ebase58:decode(<<"3SEo3LWLoPntC">>)),
   ?_assertEqual(?BIN(16#572e4794), ebase58:decode(<<"3EFU7m">>)),
   ?_assertEqual(?BIN(16#ecac89cad93923c02321), ebase58:decode(<<"EJDM8drfXA6uyA">>)),
   ?_assertEqual(?BIN(16#10c8511e), ebase58:decode(<<"Rt5zm">>)),
   ?_assertEqual(?BIN(25420294593250030202636073700053352635053786165627414518), ebase58:decode(<<"6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM">>)),
   ?_assertEqual(?BIN(16#61), ebase58:decode(<<"2g">>)),
   ?_assertEqual(?BIN(16#626262), ebase58:decode(<<"a3gV">>)),
   ?_assertEqual(?BIN(16#636363), ebase58:decode(<<"aPEr">>)),
   ?_assertEqual(?BIN(16#73696d706c792061206c6f6e6720737472696e67), ebase58:decode(<<"2cFupjhnEsSn59qHXstmK2ffpLv2">>)),
   ?_assertEqual(?BIN(16#516b6fcd0f), ebase58:decode(<<"ABnLTmg">>)),
   ?_assertEqual(?BIN(16#bf4f89001e670274dd), ebase58:decode(<<"3SEo3LWLoPntC">>)),
   ?_assertEqual(?BIN(16#572e4794), ebase58:decode(<<"3EFU7m">>)),
   ?_assertEqual(?BIN(16#ecac89cad93923c02321), ebase58:decode(<<"EJDM8drfXA6uyA">>)),
   ?_assertEqual(?BIN(16#10c8511e), ebase58:decode(<<"Rt5zm">>)),
   ?_assertEqual(<<>>, ebase58:decode(<<"">>))
  ].

invalid_suite_test_() ->
  [
   ?_assertEqual({error, invalid_base58_input}, ebase58:decode(<<"O">>)),
   ?_assertException(error, badarg, ebase58:encode("Hello World!")),
   ?_assertException(error, badarg, ebase58:decode("Hello World!"))
  ].
-endif.
