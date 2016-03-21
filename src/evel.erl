%% Copyright (c) 2016 Takeru Ohta <phjgt308@gmail.com>
%%
%% This software is released under the MIT License.
%% See the LICENSE file in the project root for full license information.
%%
%% @doc An Eventual Leader Election Library
%% @end
-module(evel).

%%----------------------------------------------------------------------------------------------------------------------
%% Exported API
%%----------------------------------------------------------------------------------------------------------------------
-export([elect/2, elect/3]).
-export([dismiss/1, dismiss/2]).
-export([find_leader/1, find_leader/2]).
-export([known_leaders/0]).
-export([is_leader/1]).
-export([get_winner/1]).
-export([get_certificate/1]).

-export_type([election_id/0]).
-export_type([candidate/0]).
-export_type([leader/0]).
-export_type([winner/0]).
-export_type([certificate/0]).
-export_type([elect_option/0]).
-export_type([find_option/0]).
-export_type([dismiss_option/0]).

%%----------------------------------------------------------------------------------------------------------------------
%% Types
%%----------------------------------------------------------------------------------------------------------------------
-type election_id() :: term().
-type candidate()   :: pid().
-type winner()      :: candidate().
-type certificate() :: pid().
-type leader()      :: {winner(), certificate()}.

-type elect_option() :: {priority, term()}
                      | {link, boolean()}
                      | find_option().

-type find_option() :: {timeout, timeout()}
                     | {voter_count, pos_integer()}.

-type dismiss_option() :: {unlink, boolean()}
                        | {async, boolean()}.

%%----------------------------------------------------------------------------------------------------------------------
%% Exported Functions
%%----------------------------------------------------------------------------------------------------------------------
%% @equiv elect(ElectionId, Candidate, [])
-spec elect(election_id(), candidate()) -> leader().
elect(ElectionId, Candidate) ->
    elect(ElectionId, Candidate, []).

-spec elect(election_id(), candidate(), [elect_option()]) -> leader().
elect(ElectionId, Candidate, Options) ->
    _ = is_pid(Candidate) orelse error(badarg, [ElectionId, Candidate, Options]),
    _ = is_list(Options) orelse error(badarg, [ElectionId, Candidate, Options]),
    evel_commission:elect(ElectionId, Candidate, Options).

%% @equiv dismiss(Leader, [])
-spec dismiss(leader()) -> ok.
dismiss(Leader) ->
    dismiss(Leader, []).

-spec dismiss(leader(), [dismiss_option()]) -> ok.
dismiss(Leader, Options) ->
    _ = is_leader(Leader) orelse error(badarg, [Leader, Options]),
    _ = is_list(Options) orelse error(badarg, [Leader, Options]),
    _ = case proplists:get_value(unlink, Options, false) of
            false -> ok;
            true  -> catch evel_agent:unlink_candidate(get_certificate(Leader))
        end,
    Async = proplists:get_value(async, Options, false),
    evel_commission:dismiss(Leader, Async).

%% @equiv find_leader(ElectionId, [])
-spec find_leader(election_id()) -> {ok, leader()} | error.
find_leader(ElectionId) ->
    find_leader(ElectionId, []).

-spec find_leader(election_id(), [find_option()]) -> {ok, leader()} | error.
find_leader(ElectionId, Options) ->
    _ = is_list(Options) orelse error(badarg, [ElectionId, Options]),
    evel_commission:find_leader(ElectionId, Options).

-spec known_leaders() -> [{election_id(), leader()}].
known_leaders() ->
    evel_commission:known_leaders().

-spec get_winner(leader()) -> winner().
get_winner(Leader) ->
    _ = is_leader(Leader) orelse error(badarg, [Leader]),
    element(1, Leader).

-spec get_certificate(leader()) -> certificate().
get_certificate(Leader) ->
    _ = is_leader(Leader) orelse error(badarg, [leader]),
    element(2, Leader).

-spec is_leader(leader()) -> boolean().
is_leader({Winner, Certificate}) -> is_pid(Winner) andalso is_pid(Certificate);
is_leader(_)                     -> false.
