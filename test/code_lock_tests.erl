-module(code_lock_tests).
-include_lib("eunit/include/eunit.hrl").

start_lock() ->
    {ok, Pid} = code_lock:start_link([1,2,3], lock),
    Pid.

stop_lock() ->
    catch code_lock:stop().

start_stop_test() ->
    Pid = start_lock(),
    ?assert(is_pid(Pid)),
    stop_lock().

correct_code_test() ->
    start_lock(),

    code_lock:button(1),
    code_lock:button(2),
    code_lock:button(3),

    timer:sleep(100),

    State = sys:get_state(code_lock),

    ?assertMatch({open,_}, element(1, State)),

    stop_lock().

wrong_code_test() ->
    start_lock(),

    code_lock:button(9),
    code_lock:button(9),
    code_lock:button(9),

    timer:sleep(100),

    State = sys:get_state(code_lock),

    ?assertMatch({locked,_}, element(1, State)),

    stop_lock().

suspend_after_three_attempts_test() ->
    start_lock(),

    %% 1 attempt
    code_lock:button(9),
    code_lock:button(9),
    code_lock:button(9),

    %% 2 attempt
    code_lock:button(8),
    code_lock:button(8),
    code_lock:button(8),

    %% 3 attempt
    code_lock:button(7),
    code_lock:button(7),
    code_lock:button(7),

    timer:sleep(100),

    State = sys:get_state(code_lock),

    ?assertMatch({suspended,_}, element(1, State)),

    stop_lock().

change_lock_button_test() ->
    start_lock(),

    Old = code_lock:set_lock_button(new_lock),

    ?assertEqual(lock, Old),

    State = sys:get_state(code_lock),

    ?assertMatch({locked,new_lock}, element(1, State)),

    stop_lock().

unlock_with_lock_button_test() ->
    start_lock(),

    code_lock:button(1),
    code_lock:button(2),
    code_lock:button(3),

    timer:sleep(100),

    code_lock:button(lock),

    timer:sleep(100),

    State = sys:get_state(code_lock),

    ?assertMatch({locked,_}, element(1, State)),

    stop_lock().

change_code_with_lock_test() ->
    start_lock(),

    code_lock:button(1),
    code_lock:button(2),
    code_lock:button(3),

    timer:sleep(10),

    code_lock:button(1),
    code_lock:button(1),
    code_lock:button(ok),

    timer:sleep(100),

    code_lock:button(1),
    code_lock:button(1),

    State = sys:get_state(code_lock),

    ?assertMatch({open,_}, element(1, State)),

    stop_lock().