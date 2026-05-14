-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/2,stop/0]).
-export([button/1,set_lock_button/1]).
-export([init/1,callback_mode/0,terminate/3]).
-export([handle_event/4]).

start_link(Code, LockButton) ->
    gen_statem:start_link(
        {local,?NAME}, ?MODULE, {Code,LockButton}, []).
stop() ->
    gen_statem:stop(?NAME).

button(Button) ->
    gen_statem:cast(?NAME, {button,Button}).
set_lock_button(LockButton) ->
    gen_statem:call(?NAME, {set_lock_button,LockButton}).

init({Code,LockButton}) ->
    process_flag(trap_exit, true),
    Data = #{code => Code, length => length(Code), buttons => [], attempt => 0, new_code => [], change => false},
    {ok, {locked,LockButton}, Data}.

callback_mode() ->
    [handle_event_function,state_enter].

%% State: locked
handle_event(enter, _OldState, {locked,_}, Data) ->
    do_lock(),
    {keep_state, Data#{buttons := []}};
handle_event(state_timeout, button, {locked,_}, Data) ->
    {keep_state, Data#{buttons := []}};
handle_event(
  cast, {button,Button}, {locked,LockButton},
  #{code := Code, length := Length, buttons := Buttons, attempt := Try} = Data) ->
    NewButtons =
        if
            length(Buttons) < Length ->
                Buttons;
            true ->
                tl(Buttons)
        end ++ [Button],
    if
        length(NewButtons) =:= Length ->
        if
            NewButtons =:= Code -> % Correct
                {next_state, {open,LockButton}, Data};
        true ->
            NewTry = Try + 1,
            if NewTry < 3 ->
                {keep_state, Data#{buttons := [], attempt := NewTry},
                [{state_timeout,30_000,button}]};
            true ->
                {next_state, {suspended,LockButton}, Data}
            end
        end;
	true -> % Incomplete | Incorrect
            {keep_state, Data#{buttons := NewButtons},
             [{state_timeout,30_000,button}]} % Time in milliseconds
    end;
%%
%% State: open
handle_event(enter, _OldState, {open,_}, _Data) ->
    do_unlock(),
    {keep_state_and_data,
     [{state_timeout,10_000,lock}]}; % Time in milliseconds
handle_event(state_timeout, lock, {open,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data#{new_code := [], change := false}};
handle_event(cast, {button,LockButton}, {open,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data};
handle_event(cast, {button,Button}, {open,LockButton},
    #{change := false} = Data) when Button =/= LockButton, Button =/= ok ->
    {keep_state, Data#{new_code := [Button], change := true},
    [{state_timeout,10_000,button}]};
handle_event(cast, {button,Button}, {open,_},
    #{new_code := Code, change := true} = Data) when Button =/= ok ->
        {keep_state, Data#{new_code := [Button] ++ Code},
        [{state_timeout,10_000,button}]};
handle_event(cast, {button,ok}, {open,LockButton},
    #{new_code := NewCode, change := true} = Data) ->
        io:format("New Code = ~p~n", [NewCode]),
        {next_state, {locked,LockButton},
        Data#{code := NewCode, length := length(NewCode),
              new_code := [], change := false}};


%%
%% State: suspended
handle_event(enter, _OldState, {suspended,_}, _Data) ->
    do_suspended(),
    {keep_state_and_data,
     [{state_timeout,10_000,lock}]}; % Time in milliseconds
handle_event(state_timeout, lock, {suspended,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data};
handle_event(cast, {button,LockButton}, {suspended,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data};
handle_event(cast, {button,_}, {suspended,_}, _Data) ->
    error(),
    {keep_state_and_data, []};
%%
%% Common events
handle_event(
  {call,From}, {set_lock_button,NewLockButton},
  {StateName,OldLockButton}, Data) ->
    {next_state, {StateName,NewLockButton}, Data,
     [{reply,From,OldLockButton}]}.
do_lock() ->
    io:format("Locked~n", []).
do_unlock() ->
    io:format("Open~n", []).
do_suspended() ->
    io:format("Suspended~n", []).
error() ->
    io:format("Error~n", []).

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.
